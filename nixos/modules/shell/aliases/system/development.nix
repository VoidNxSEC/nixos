{ ... }:
{

}
#grep -rn 'std::env::var\|os\.getenv\|env!('/home/kernelcore/master/staging/neoland/src/ /home/kernelcore/master/staging/neoland/agents/ --include="*.rs" --include="*.py" | grep -v '__pycache__\|target/' | grep -oP '(?<=var\(|getenv\(|env!\()["\x27][A-Z][A-Z0-9_]+["\x27]' | sort -u
