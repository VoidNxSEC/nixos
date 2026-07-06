#!/usr/bin/env bash
# ir_capture.sh — Incident Response: process forensics, integrity, encryption
# Targets: 54966 (PID1) and 28133 (PID2)
# Chain: freeze → snapshot1 → snapshot2 → manifest → unfreeze → behavioral → encrypt

set -euo pipefail

PIDS=(54966 28133)
TS=$(date +%Y%m%d_%H%M%S)
WORKDIR="/tmp/ir_${TS}"
ARCHIVE="${WORKDIR}.tar.gz"
ENCRYPTED="${ARCHIVE}.enc"
KEYFILE="${WORKDIR}.key"
MANIFEST="${WORKDIR}/MANIFEST.sha256"
STRACE_SECS=8
EBPF_SECS=8

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${GREEN}[$(date +%H:%M:%S)] $*${NC}"; }
warn() { echo -e "${YELLOW}[WARN] $*${NC}"; }
die()  { echo -e "${RED}[FATAL] $*${NC}" >&2; exit 1; }
sep()  { echo -e "${CYAN}────────────────────────────────────────────────────${NC}"; }

[[ $EUID -eq 0 ]] || warn "Sem root — alguns dados do /proc podem ser inacessíveis"
mkdir -p "${WORKDIR}"

# ── FREEZE / UNFREEZE ───────────────────────────────────────────

freeze_all() {
    sep; log "FREEZE: ${PIDS[*]}"
    for pid in "${PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -STOP "$pid" && log "  STOPPED $pid"
            pgid=$(ps -o pgid= -p "$pid" 2>/dev/null | tr -d ' ') || true
            [[ -n "$pgid" && "$pgid" != "$pid" ]] && kill -STOP -"$pgid" 2>/dev/null && log "  STOPPED group $pgid"
        else
            warn "  PID $pid não existe"
        fi
    done
}

unfreeze_all() {
    sep; log "UNFREEZE: ${PIDS[*]}"
    for pid in "${PIDS[@]}"; do
        kill -CONT "$pid" 2>/dev/null && log "  CONTINUED $pid" || warn "  $pid não respondeu"
        pgid=$(ps -o pgid= -p "$pid" 2>/dev/null | tr -d ' ') || true
        [[ -n "$pgid" && "$pgid" != "$pid" ]] && kill -CONT -"$pgid" 2>/dev/null || true
    done
}

# ── SNAPSHOT ESTÁTICO (processo congelado) ──────────────────────

collect_static() {
    local name="$1"
    local dir="${WORKDIR}/${name}"
    sep; log "SNAPSHOT ESTÁTICO: ${name}"

    for pid in "${PIDS[@]}"; do
        local pd="${dir}/${pid}"
        mkdir -p "${pd}/proc"

        log "  Coletando PID ${pid}..."

        # /proc entries
        for entry in cmdline comm environ maps smaps status stat statm syscall \
                     wchan stack limits io loginuid oom_score oom_adj \
                     net/tcp net/tcp6 net/udp net/udp6 net/unix; do
            local src="/proc/${pid}/${entry}"
            [[ -e "$src" ]] && { mkdir -p "${pd}/proc/$(dirname "$entry")"; \
                cp -r "$src" "${pd}/proc/${entry}" 2>/dev/null || true; }
        done

        # FD listing
        ls -la "/proc/${pid}/fd/"    > "${pd}/proc/fd_list.txt"   2>/dev/null || true
        ls -la "/proc/${pid}/fdinfo/"> "${pd}/proc/fdinfo_list.txt" 2>/dev/null || true

        # Threads
        ls "/proc/${pid}/task/"      > "${pd}/threads.txt"        2>/dev/null || true

        # Executable path + hash (chain of custody)
        local exe
        exe=$(readlink -f "/proc/${pid}/exe" 2>/dev/null) || true
        if [[ -n "$exe" && -f "$exe" ]]; then
            echo "$exe" > "${pd}/exe_path.txt"
            sha256sum "$exe" > "${pd}/exe.sha256"
            md5sum    "$exe" > "${pd}/exe.md5"
        fi

        # Environment (strings safe)
        strings "/proc/${pid}/environ" > "${pd}/environ_strings.txt" 2>/dev/null || true

        # Tools externos
        lsof  -p "$pid"              > "${pd}/lsof.txt"           2>/dev/null || true
        ss    -tnp | grep "pid=${pid}" > "${pd}/ss_connections.txt" 2>/dev/null || true
        ps    -p "$pid" -o pid,ppid,pgid,sid,user,pri,ni,vsz,rss,stat,start,time,cmd \
                                     > "${pd}/ps_detail.txt"      2>/dev/null || true
        pstree -p "$pid"             > "${pd}/pstree.txt"         2>/dev/null || true

        log "  PID ${pid} coletado."
    done

    # Estado geral do sistema no momento do snapshot
    local sd="${dir}/system"
    mkdir -p "$sd"
    date -u +"%Y-%m-%dT%H:%M:%SZ"   > "${sd}/timestamp_utc.txt"
    uname -a                         > "${sd}/uname.txt"
    ps auxf                          > "${sd}/ps_full.txt"        2>/dev/null || true
    ss -tulpn                        > "${sd}/ss_all.txt"         2>/dev/null || true
    netstat -tulpn                   > "${sd}/netstat.txt"        2>/dev/null || true
    cat /proc/loadavg                > "${sd}/loadavg.txt"        2>/dev/null || true
    free -h                          > "${sd}/memory.txt"         2>/dev/null || true

    log "Snapshot ${name} completo."
}

# ── SNAPSHOT COMPORTAMENTAL (processo vivo) ─────────────────────

collect_behavioral() {
    local dir="${WORKDIR}/behavioral_final"
    sep; log "SNAPSHOT COMPORTAMENTAL (live)"

    for pid in "${PIDS[@]}"; do
        local pd="${dir}/${pid}"
        mkdir -p "$pd"
        log "  Rastreando PID ${pid}..."

        # strace: syscalls com timestamps e duração
        log "    strace ${STRACE_SECS}s..."
        timeout "${STRACE_SECS}" strace -p "$pid" -f -tt -T -y \
            -o "${pd}/strace.txt" 2>/dev/null || true

        # eBPF via bpftrace (se disponível)
        if command -v bpftrace &>/dev/null; then
            log "    bpftrace: openat/read/write ${EBPF_SECS}s..."
            timeout "${EBPF_SECS}" bpftrace -e "
                tracepoint:syscalls:sys_enter_openat /pid == ${pid}/ {
                    printf(\"openat  %s\n\", str(args->filename));
                }
                tracepoint:syscalls:sys_enter_read  /pid == ${pid}/ {
                    printf(\"read    fd=%d count=%d\n\", args->fd, args->count);
                }
                tracepoint:syscalls:sys_enter_write /pid == ${pid}/ {
                    printf(\"write   fd=%d count=%d\n\", args->fd, args->count);
                }
                tracepoint:syscalls:sys_enter_connect /pid == ${pid}/ {
                    printf(\"connect fd=%d\n\", args->fd);
                }
            " > "${pd}/bpftrace.txt" 2>/dev/null || warn "    bpftrace falhou (permissão/kernel)"

            # Network activity via eBPF
            log "    bpftrace: network ${EBPF_SECS}s..."
            timeout "${EBPF_SECS}" bpftrace -e "
                kprobe:tcp_sendmsg /pid == ${pid}/ {
                    printf(\"tcp_send pid=%d size=%d\n\", pid, arg2);
                }
                kprobe:tcp_recvmsg /pid == ${pid}/ {
                    printf(\"tcp_recv pid=%d\n\", pid);
                }
            " > "${pd}/bpftrace_net.txt" 2>/dev/null || true
        else
            warn "    bpftrace não encontrado — pulando eBPF"
        fi

        # perf stat
        if command -v perf &>/dev/null; then
            log "    perf stat 3s..."
            timeout 3 perf stat -p "$pid" 2> "${pd}/perf_stat.txt" || true
        fi

        # I/O delta (dois pontos no tempo)
        cat "/proc/${pid}/io" > "${pd}/io_before.txt" 2>/dev/null || true
        sleep 2
        cat "/proc/${pid}/io" > "${pd}/io_after.txt"  2>/dev/null || true

        # Conexões live após comportamento
        ss -tnp | grep "pid=${pid}" > "${pd}/ss_live.txt" 2>/dev/null || true
        lsof -p "$pid"              > "${pd}/lsof_live.txt" 2>/dev/null || true

        log "  PID ${pid} comportamento coletado."
    done

    # Snapshot do sistema após observação
    local sd="${dir}/system"
    mkdir -p "$sd"
    date -u +"%Y-%m-%dT%H:%M:%SZ" > "${sd}/timestamp_utc.txt"
    ss -tulpn                      > "${sd}/ss_final.txt"  2>/dev/null || true
    ps auxf                        > "${sd}/ps_final.txt"  2>/dev/null || true

    log "Snapshot comportamental completo."
}

# ── INTEGRIDADE ─────────────────────────────────────────────────

generate_manifest() {
    sep; log "Gerando manifesto de integridade..."
    find "${WORKDIR}" -type f ! -name "MANIFEST.sha256" \
        -exec sha256sum {} \; | sort > "${MANIFEST}"
    sha256sum "${MANIFEST}" > "${WORKDIR}/MANIFEST.meta.sha256"
    log "Manifesto: ${MANIFEST}"
    log "Meta-hash: $(cat ${WORKDIR}/MANIFEST.meta.sha256)"
}

# ── ENCRIPTAÇÃO ─────────────────────────────────────────────────

encrypt_archive() {
    sep; log "Comprimindo evidências..."
    tar -czf "${ARCHIVE}" -C "$(dirname "${WORKDIR}")" "$(basename "${WORKDIR}")"

    log "Gerando chave AES-256..."
    openssl rand -base64 32 > "${KEYFILE}"
    chmod 600 "${KEYFILE}"

    log "Encriptando (AES-256-CBC + PBKDF2)..."
    openssl enc -aes-256-cbc -pbkdf2 -iter 200000 \
        -in  "${ARCHIVE}" \
        -out "${ENCRYPTED}" \
        -pass file:"${KEYFILE}"

    # Hash do arquivo encriptado (chain of custody)
    sha256sum "${ENCRYPTED}" > "${ENCRYPTED}.sha256"
    sha256sum "${KEYFILE}"   > "${KEYFILE}.sha256"

    rm -f "${ARCHIVE}"

    log "Arquivo encriptado: ${ENCRYPTED}"
    log "Chave salva em:     ${KEYFILE}"
}

# ── RELATÓRIO FINAL ─────────────────────────────────────────────

report() {
    sep
    echo -e "${CYAN}"
    echo "  ╔══════════════════════════════════════════════════╗"
    echo "  ║         INCIDENT RESPONSE — CAPTURA OK           ║"
    echo "  ╠══════════════════════════════════════════════════╣"
    printf  "  ║  Timestamp  : %-33s║\n" "${TS}"
    printf  "  ║  Targets    : %-33s║\n" "${PIDS[*]}"
    printf  "  ║  Workdir    : %-33s║\n" "${WORKDIR}"
    printf  "  ║  Encrypted  : %-33s║\n" "$(basename ${ENCRYPTED})"
    printf  "  ║  Key        : %-33s║\n" "$(basename ${KEYFILE})"
    echo "  ╠══════════════════════════════════════════════════╣"
    echo "  ║  HASH DO ARQUIVO ENCRIPTADO (chain of custody):  ║"
    echo "  ║  $(cat ${ENCRYPTED}.sha256 | awk '{print $1}' | cut -c1-48)  ║"
    echo "  ╠══════════════════════════════════════════════════╣"
    echo "  ║  Para decriptar:                                 ║"
    echo "  ║  openssl enc -d -aes-256-cbc -pbkdf2            ║"
    echo "  ║    -iter 200000                                  ║"
    echo "  ║    -in  <encrypted>                              ║"
    echo "  ║    -out recovered.tar.gz                         ║"
    echo "  ║    -pass file:<keyfile>                          ║"
    echo "  ╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ══════════════════════════════════════════════════════════════════
#  MAIN
# ══════════════════════════════════════════════════════════════════

sep; log "INÍCIO DA CAPTURA — targets: ${PIDS[*]}"

# 1. Congela ambos
freeze_all

# 2. Snapshot 1 (estado congelado — primeira marca)
collect_static "snapshot_1_frozen"

# 3. Snapshot 2 (segunda passagem — confirma consistência)
collect_static "snapshot_2_frozen"

# 4. Manifesto parcial (antes de descongelar)
generate_manifest

# 5. Descongela ambos
unfreeze_all

# 6. Snapshot comportamental pesado (live: strace + eBPF + perf)
collect_behavioral

# 7. Manifesto final (inclui dados comportamentais)
generate_manifest

# 8. Encripta tudo
encrypt_archive

# 9. Relatório
report
