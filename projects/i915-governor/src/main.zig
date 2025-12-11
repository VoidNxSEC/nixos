const std = @import("std");
const fs = std.fs;
const io = std.io;
const fmt = std.fmt;

const PsiStats = struct {
    some_avg10: f32,
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("INFO: i915 Governor v0.4 - GPU + MEMORY MONITOR\n", .{});

    var buffer: [1024]u8 = undefined;

    // Configurações Ajustadas
    const MEM_THRESHOLD: f32 = 2.0;    // Baixei de 15% para 2% (mais sensível)
    const GPU_THRESHOLD: u64 = 95;     // 95% de uso da GPU
    var cooldown_counter: u32 = 0;

    // Tenta descobrir qual card é a Intel (geralmente card0 ou card1)
    // Ajuste aqui se necessário:
    const gpu_busy_path = "/sys/class/drm/card1/device/gpu_busy_percent";

    while (true) {
        const pressure = try readMemoryPressure(&buffer);
        const gpu_usage = readGpuBusy(gpu_busy_path, &buffer) catch 0; // Se falhar, assume 0

        // Visualização Debug no log (para você ver o que está acontecendo)
        if (gpu_usage > 50 or pressure.some_avg10 > 0.1) {
             try stdout.print("STATUS: Mem: {d:.2}% | GPU: {d}%\n", .{pressure.some_avg10, gpu_usage});
        }

        // Lógica de Intervenção Combinada
        // Se a memória começar a sofrer OU a GPU estiver fritando
        if ((pressure.some_avg10 > MEM_THRESHOLD) or (gpu_usage > GPU_THRESHOLD)) {
            if (cooldown_counter == 0) {
                try stdout.print("CRITICAL: CONGESTIONAMENTO DETECTADO! (Mem:{d:.2}% GPU:{d}%)\n", .{pressure.some_avg10, gpu_usage});

                // AÇÃO 1: Drop Caches (Alivia o sistema de arquivos)
                try writeSysctl("/proc/sys/vm/drop_caches", "1");

                // AÇÃO 2: Compactação (Tenta salvar alocação de texturas grandes)
                try writeSysctl("/proc/sys/vm/compact_memory", "1");

                // NOVA AÇÃO: Talvez você queira limitar o Chromium aqui no futuro
                // Por enquanto, limpar a memória deve ajudar a GPU a "respirar"

                cooldown_counter = 5; // 5 segundos de espera
            }
        }

        if (cooldown_counter > 0) cooldown_counter -= 1;
        std.time.sleep(1 * std.time.ns_per_s);
    }
}

// Lê a porcentagem de uso da GPU (arquivo contém apenas um número inteiro)
fn readGpuBusy(path: []const u8, buffer: []u8) !u64 {
    var file = fs.openFileAbsolute(path, .{ .mode = .read_only }) catch return 0;
    defer file.close();

    const bytes_read = try file.readAll(buffer);
    const content = std.mem.trim(u8, buffer[0..bytes_read], " \n\r");

    return fmt.parseInt(u64, content, 10);
}

// --- Helpers Anteriores ---
fn writeSysctl(path: []const u8, value: []const u8) !void {
    var file = fs.openFileAbsolute(path, .{ .mode = .write_only }) catch return;
    defer file.close();
    _ = try file.write(value);
}

fn readMemoryPressure(buffer: []u8) !PsiStats {
    var file = try fs.openFileAbsolute("/proc/pressure/memory", .{ .mode = .read_only });
    defer file.close();
    const bytes_read = try file.readAll(buffer);
    var stats = PsiStats{ .some_avg10 = 0 };
    var lines = std.mem.tokenizeSequence(u8, buffer[0..bytes_read], "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "some ")) stats.some_avg10 = try parseMetric(line, "avg10=");
    }
    return stats;
}

fn parseMetric(line: []const u8, key: []const u8) !f32 {
    const idx = std.mem.indexOf(u8, line, key) orelse return 0.0;
    const start = idx + key.len;
    var end = start;
    while (end < line.len and line[end] != ' ') : (end += 1) {}
    return fmt.parseFloat(f32, line[start..end]);
}
