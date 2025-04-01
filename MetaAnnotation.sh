#!/bin/bash
#
# MetaAnnotation v1.0
# 一个用于宏基因组分析的流程脚本，使用Kraken2和Bracken进行分类学注释
#
# 作者：Hahn
# 日期：2025-03-27

set -e  # 出错时退出

# 默认配置值
VERSION="1.0.0"
DEFAULT_MAX_PARALLEL=4
DEFAULT_THREADS=16
DEFAULT_GROUP_SIZE=100
DEFAULT_READ_LENGTH=150
DEFAULT_CONFIDENCE=0.1
DEFAULT_MIN_HIT_GROUPS=3

# ANSI颜色代码，提高可读性
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# ----- 工具函数 -----

# 带时间戳的日志消息
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    case "$level" in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $timestamp - $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $timestamp - $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $timestamp - $message"
            ;;
        *)
            echo -e "${BLUE}[$level]${NC} $timestamp - $message"
            ;;
    esac
}

# 显示使用信息
function show_usage {
    cat << EOF
MetaGenPipe v${VERSION}
一个综合性的宏基因组分析流程

用法:
    ./metagen.sh [命令] [选项]

命令:
    setup         创建目录结构
    group         将样本分组成批次
    kraken        运行Kraken2分析
    bracken       运行Bracken分析
    mpa           生成MPA格式文件
    enhance       创建增强的分类文件
    all           运行完整工作流程

全局选项:
    -h, --help            显示此帮助信息
    -v, --version         显示版本信息
    -c, --config 文件     指定配置文件

ALL选项:
    -d, --dir 目录        分析的基础目录
    -i, --input 目录      包含配对末端读取的输入目录
    -b, --database 目录   Kraken2/Bracken数据库目录
    -s, --size 数字       每组样本数量 (默认: 100)
    -p, --parallel 数字   最大并行作业数 (默认: 4)
    -t, --threads 数字    每个作业的线程数 (默认: 16)
    -r, --read-len 数字   读取长度 (默认: 150)
    -c, --confidence 数字 置信度阈值 (默认: 0.1)
    -m, --min-hits 数字   最小命中组数 (默认: 3)
    --r1-pattern 字符串   R1文件模式 (默认: "*.1.paired.fq.gz")
    --r2-pattern 字符串   R2文件模式 (默认: 自动从R1模式生成)

SETUP选项:
    -d, --dir 目录        分析的基础目录

GROUP选项:
    -i, --input 目录      包含配对末端读取的输入目录
    -o, --output 目录     分组样本的输出目录
    -s, --size 数字       每组样本数量 (默认: ${DEFAULT_GROUP_SIZE})
    -p, --pattern 字符串  匹配的文件模式 (默认: "*.1.paired.fq.gz")

KRAKEN选项:
    -i, --input 目录      包含分组样本的输入目录
    -o, --output 目录     Kraken2结果的输出目录
    -d, --database 目录   Kraken2数据库目录
    -p, --parallel 数字   最大并行作业数 (默认: ${DEFAULT_MAX_PARALLEL})
    -t, --threads 数字    每个作业的线程数 (默认: ${DEFAULT_THREADS})
    -c, --confidence 数字 置信度阈值 (默认: ${DEFAULT_CONFIDENCE})
    -m, --min-hits 数字   最小命中组数 (默认: ${DEFAULT_MIN_HIT_GROUPS})

BRACKEN选项:
    -i, --input 目录      包含Kraken2结果的输入目录
    -o, --output 目录     Bracken结果的输出目录
    -d, --database 目录   Kraken2/Bracken数据库目录
    -r, --read-len 数字   读取长度 (默认: ${DEFAULT_READ_LENGTH})

MPA选项:
    -k, --kraken 目录     包含Kraken2结果的目录
    -o, --output 目录     MPA格式的输出目录

ENHANCE选项:
    -m, --mpa 文件        MPA格式文件
    -b, --bracken 目录    包含Bracken结果的目录
    -o, --output 目录     增强文件的输出目录

详细文档，请访问:https://github.com/hahntoh/MetaAnnotation
EOF
}

# 显示版本信息
function show_version {
    echo "MetaGenPipe v${VERSION}"
    echo "一个综合性的宏基因组分析流程"
    echo "版权所有 (c) 2025"
}

# 检查所需依赖项
function check_dependencies {
    local missing=0
    
    log "SETUP" "检查依赖项..."
    
    # 检查Kraken2
    if ! command -v kraken2 &> /dev/null; then
        log "ERROR" "kraken2未安装或不在PATH中"
        missing=1
    else
        log "INFO" "✓ kraken2: $(kraken2 --version | head -n 1)"
    fi
    
    # 检查Bracken
    if ! command -v bracken &> /dev/null; then
        log "ERROR" "bracken未安装或不在PATH中"
        missing=1
    else
        log "INFO" "✓ bracken: $(bracken -v 2>&1 | head -n 1)"
    fi
    
    # 检查Python3
    if ! command -v python3 &> /dev/null; then
        log "ERROR" "python3未安装或不在PATH中"
        missing=1
    else
        log "INFO" "✓ python3: $(python3 --version)"
    fi
    
    # 检查pandas
    if ! python3 -c "import pandas" &> /dev/null; then
        log "ERROR" "Python包'pandas'未安装"
        log "INFO" "  使用以下命令安装: pip3 install pandas"
        missing=1
    else
        log "INFO" "✓ pandas: $(python3 -c "import pandas; print(pandas.__version__)")"
    fi
    
    if [ $missing -eq 1 ]; then
        log "ERROR" "请安装缺失的依赖项并重试。"
        exit 1
    fi
    
    log "INFO" "所有依赖项均已满足。"
}

# 从文件加载配置
function load_config {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        log "ERROR" "未找到配置文件: $config_file"
        exit 1
    fi
    
    log "INFO" "从以下位置加载配置: $config_file"
    source "$config_file"
}

# 创建目录结构
function setup_directories {
    local base_dir="$1"
    
    if [ -z "$base_dir" ]; then
        log "ERROR" "未指定基础目录"
        exit 1
    fi
    
    log "INFO" "在以下位置创建目录结构: $base_dir"
    
    # 创建主要目录
    mkdir -p "${base_dir}/1.rawdata"
    mkdir -p "${base_dir}/2.cleandata"
    mkdir -p "${base_dir}/2.cleandata/grouped"
    mkdir -p "${base_dir}/5.annotation/kraken2"
    mkdir -p "${base_dir}/5.annotation/kraken2/logs"
    mkdir -p "${base_dir}/5.annotation/kraken2/scripts"
    mkdir -p "${base_dir}/5.annotation/bracken"
    mkdir -p "${base_dir}/5.annotation/bracken/species"
    mkdir -p "${base_dir}/5.annotation/bracken/genus"
    mkdir -p "${base_dir}/5.annotation/bracken/family"
    mkdir -p "${base_dir}/5.annotation/bracken/order"
    mkdir -p "${base_dir}/5.annotation/bracken/class"
    mkdir -p "${base_dir}/5.annotation/bracken/phylum"
    mkdir -p "${base_dir}/5.annotation/bracken/domain"
    mkdir -p "${base_dir}/5.annotation/bracken/enhanced"
    mkdir -p "${base_dir}/logs"
    mkdir -p "${base_dir}/scripts"
    
    log "SUCCESS" "目录结构创建成功。"
}




# Part 2

# 将样本分组成批次
function group_samples {
    local source_dir="$1"
    local target_dir="$2"
    local group_size="$3"
    local r1_pattern="$4"
    local r2_pattern="$5"
    
    if [ -z "$source_dir" ] || [ -z "$target_dir" ]; then
        log "ERROR" "未指定源目录或目标目录"
        exit 1
    fi
    
    # 设置默认值
    if [ -z "$group_size" ]; then
        group_size=${DEFAULT_GROUP_SIZE}
    fi
    
    # 设置默认的文件模式
    if [ -z "$r1_pattern" ]; then
        r1_pattern="*.1.paired.fq.gz"
    fi
    
    # 如果未指定R2模式，则从R1模式自动生成
    if [ -z "$r2_pattern" ]; then
        # 尝试常见的模式替换
        if [[ "$r1_pattern" == *".1."* ]]; then
            r2_pattern="${r1_pattern/.1./.2.}"
        elif [[ "$r1_pattern" == *"_1."* ]]; then
            r2_pattern="${r1_pattern/_1./_2.}"
        elif [[ "$r1_pattern" == *".R1."* ]]; then
            r2_pattern="${r1_pattern/.R1./.R2.}"
        elif [[ "$r1_pattern" == *"_R1_"* ]]; then
            r2_pattern="${r1_pattern/_R1_/_R2_}"
        elif [[ "$r1_pattern" == *"_R1."* ]]; then
            r2_pattern="${r1_pattern/_R1./_R2.}"
        else
            # 如果不匹配任何已知模式，提示用户手动指定
            log "ERROR" "无法从R1模式自动生成R2模式，请使用--r2-pattern显式指定"
            exit 1
        fi
    fi
    
    local log_dir="$(dirname "$target_dir")/../logs"
    mkdir -p "$log_dir"
    local log_file="${log_dir}/group_samples_$(date +%Y%m%d_%H%M%S).log"
    
    log "INFO" "开始样本分组" | tee -a "$log_file"
    log "INFO" "源目录: $source_dir" | tee -a "$log_file"
    log "INFO" "目标目录: $target_dir" | tee -a "$log_file"
    log "INFO" "组大小: $group_size" | tee -a "$log_file"
    log "INFO" "R1文件模式: $r1_pattern" | tee -a "$log_file"
    log "INFO" "R2文件模式: $r2_pattern" | tee -a "$log_file"
    
    # 查找所有匹配R1模式的文件
    local r1_files=$(find "$source_dir" -name "$r1_pattern" 2>/dev/null)
    
    if [ -z "$r1_files" ]; then
        log "ERROR" "在$source_dir中未找到匹配$r1_pattern的文件" | tee -a "$log_file"
        exit 1
    fi
    
    # 计算找到的R1文件数
    local r1_count=$(echo "$r1_files" | wc -l)
    log "INFO" "找到$r1_count个R1文件" | tee -a "$log_file"
    
    # 计算所需的组数
    local num_groups=$(( (r1_count + group_size - 1) / group_size ))
    log "INFO" "将创建$num_groups组，每组最多包含$group_size个样本对" | tee -a "$log_file"
    
    # 如果组目录不存在，则创建它们
    for ((i=1; i<=num_groups; i++)); do
        local group_dir="$target_dir/group$i"
        mkdir -p "$group_dir"
        log "INFO" "创建了目录: $group_dir" | tee -a "$log_file"
    done
    
    # 将样本分配到组中
    local count=0
    local group=1
    local successful_links=0
    
    for r1_file in $r1_files; do
        # 获取R1文件名
        local r1_basename=$(basename "$r1_file")
        
        # 从R1文件名生成R2文件名
        # 这是一个简单的替换，如果文件命名更复杂，可能需要调整
        local r2_basename=$(basename "$r1_file" | sed "s|$r1_pattern|$r2_pattern|g")
        if [ "$r1_basename" = "$r2_basename" ]; then
            # 如果替换失败，尝试使用模式替换
            if [[ "$r1_pattern" == *".1."* ]] && [[ "$r2_pattern" == *".2."* ]]; then
                r2_basename="${r1_basename/.1./.2.}"
            elif [[ "$r1_pattern" == *"_1."* ]] && [[ "$r2_pattern" == *"_2."* ]]; then
                r2_basename="${r1_basename/_1./_2.}"
            elif [[ "$r1_pattern" == *".R1."* ]] && [[ "$r2_pattern" == *".R2."* ]]; then
                r2_basename="${r1_basename/.R1./.R2.}"
            elif [[ "$r1_pattern" == *"_R1_"* ]] && [[ "$r2_pattern" == *"_R2_"* ]]; then
                r2_basename="${r1_basename/_R1_/_R2_}"
            elif [[ "$r1_pattern" == *"_R1."* ]] && [[ "$r2_pattern" == *"_R2."* ]]; then
                r2_basename="${r1_basename/_R1./_R2.}"
            fi
        fi
        
        local r2_file="$source_dir/$r2_basename"
        
        # 检查两个配对文件是否都存在
        if [ -f "$r1_file" ] && [ -f "$r2_file" ]; then
            # 为R1和R2文件创建符号链接
            ln -sf "$(realpath "$r1_file")" "$target_dir/group$group/$r1_basename"
            ln -sf "$(realpath "$r2_file")" "$target_dir/group$group/$r2_basename"
            log "INFO" "已将$r1_basename和$r2_basename链接到group$group" | tee -a "$log_file"
            
            # 增加计数器并检查是否需要移至下一组
            count=$((count + 1))
            successful_links=$((successful_links + 1))
            if [ $count -eq $group_size ]; then
                group=$((group + 1))
                count=0
            fi
        else
            log "WARN" "无法找到匹配的配对文件: $r1_basename和$r2_basename" | tee -a "$log_file"
        fi
    done
    
    log "SUCCESS" "已在$num_groups组中完成符号链接的创建，成功链接了$successful_links对文件" | tee -a "$log_file"
    log "INFO" "结束时间: $(date)" | tee -a "$log_file"
}

# 创建Kraken2脚本
function create_kraken_scripts {
    local input_dir="$1"
    local output_dir="$2"
    local database_dir="$3"
    local threads="$4"
    local confidence="$5"
    local min_hit_groups="$6"
    local file_pattern="$7"
    
    # 设置默认值
    if [ -z "$file_pattern" ]; then
        file_pattern="*.1.paired.fq.gz"
    fi
    
    local scripts_dir="${output_dir}/scripts"
    mkdir -p "$scripts_dir"
    
    log "INFO" "创建Kraken2脚本..."
    
    # 查找所有组目录
    local group_dirs=$(find "$input_dir" -type d -name "group*" | sort)
    
    if [ -z "$group_dirs" ]; then
        log "ERROR" "在$input_dir中未找到组目录"
        exit 1
    fi
    
    # 提取基本模式以确定第二读取文件模式
    local base_pattern="${file_pattern%.*.*}"
    local extension="${file_pattern#*.*.}"
    local r1_pattern="${file_pattern}"
    local r2_pattern="${base_pattern}.2.${extension}"
    
    # 为每个组创建单独的脚本
    for group_dir in $group_dirs; do
        local group_name=$(basename "$group_dir")
        local script_file="${scripts_dir}/process_${group_name}.sh"
        
        # 写入脚本文件
        cat > "$script_file" << EOF
#!/bin/bash

# 自动生成的处理${group_name}的脚本
# 生成于: $(date)

# 设置路径
INPUT_DIR="${input_dir}/${group_name}"
OUTPUT_DIR="${output_dir}"
DATABASE_DIR="${database_dir}"
LOG_DIR="${output_dir}/logs/${group_name}"

# 设置参数
THREADS=${threads}

# 创建输出和日志目录
mkdir -p "\$OUTPUT_DIR"
mkdir -p "\$LOG_DIR"

# 日志文件
LOG_FILE="\$LOG_DIR/${group_name}_process.log"

echo "===== 开始处理${group_name} =====" | tee -a "\$LOG_FILE"
echo "开始时间: \$(date)" | tee -a "\$LOG_FILE"

# 查找所有配对末端文件
FQ1_FILES=\$(find "\$INPUT_DIR" -name "$r1_pattern")

# 首先打印命令行接收到的模式
echo "命令行R1模式: $r1_pattern" | tee -a "\$LOG_FILE" 
echo "命令行R2模式: $r2_pattern" | tee -a "\$LOG_FILE"

# 处理每个样本
for FQ1 in \$FQ1_FILES; do
    # 获取文件基本名称和目录
    BASE_NAME=\$(basename "\$FQ1")
    DIR_NAME=\$(dirname "\$FQ1")
    
    # 尝试多种常见的替换模式找到R2文件
    # 1. 常见模式1: .1. → .2.
    R2_NAME_1=\$(echo "\$BASE_NAME" | sed 's/\.1\./\.2\./g')
    FQ2_1="\$DIR_NAME/\$R2_NAME_1"
    
    # 2. 常见模式2: _1. → _2.
    R2_NAME_2=\$(echo "\$BASE_NAME" | sed 's/_1\./_2\./g')
    FQ2_2="\$DIR_NAME/\$R2_NAME_2"
    
    # 3. 常见模式3: _R1_ → _R2_
    R2_NAME_3=\$(echo "\$BASE_NAME" | sed 's/_R1_/_R2_/g')
    FQ2_3="\$DIR_NAME/\$R2_NAME_3"
    
    # 4. 常见模式4: _R1. → _R2.
    R2_NAME_4=\$(echo "\$BASE_NAME" | sed 's/_R1\./_R2\./g')
    FQ2_4="\$DIR_NAME/\$R2_NAME_4"
    
    # 5. 将数字1替换为2（最后的备选方案）
    R2_NAME_5=\$(echo "\$BASE_NAME" | sed 's/1/2/g')
    FQ2_5="\$DIR_NAME/\$R2_NAME_5"
    
    # 检查哪个R2文件存在
    if [ -f "\$FQ2_1" ]; then
        FQ2="\$FQ2_1"
        R2_NAME="\$R2_NAME_1"
        echo "找到R2文件(模式1): \$FQ2" | tee -a "\$LOG_FILE"
    elif [ -f "\$FQ2_2" ]; then
        FQ2="\$FQ2_2"
        R2_NAME="\$R2_NAME_2"
        echo "找到R2文件(模式2): \$FQ2" | tee -a "\$LOG_FILE"
    elif [ -f "\$FQ2_3" ]; then
        FQ2="\$FQ2_3"
        R2_NAME="\$R2_NAME_3"
        echo "找到R2文件(模式3): \$FQ2" | tee -a "\$LOG_FILE"
    elif [ -f "\$FQ2_4" ]; then
        FQ2="\$FQ2_4"
        R2_NAME="\$R2_NAME_4"
        echo "找到R2文件(模式4): \$FQ2" | tee -a "\$LOG_FILE"
    elif [ -f "\$FQ2_5" ]; then
        FQ2="\$FQ2_5"
        R2_NAME="\$R2_NAME_5"
        echo "找到R2文件(模式5): \$FQ2" | tee -a "\$LOG_FILE"
    else
        echo "警告: 未找到配对文件，尝试过所有常见模式，跳过\$BASE_NAME" | tee -a "\$LOG_FILE"
        continue
    fi
    
    # 提取样本ID (去除文件扩展名)
    SAMPLE_ID=\$(echo "\$BASE_NAME" | sed 's/\.un\..*$//')
    
    # 如果样本ID为空，则使用基本文件名
    if [ -z "\$SAMPLE_ID" ]; then
        SAMPLE_ID=\$(echo "\$BASE_NAME" | sed 's/\.[^.]*$//')
    fi
    
    # 输出调试信息
    echo "处理样本: \$SAMPLE_ID" | tee -a "\$LOG_FILE"
    echo "原始文件名: \$BASE_NAME" | tee -a "\$LOG_FILE"
    echo "R2文件名: \$R2_NAME" | tee -a "\$LOG_FILE"
    echo "R1文件: \$FQ1" | tee -a "\$LOG_FILE" 
    echo "R2文件: \$FQ2" | tee -a "\$LOG_FILE"
    
    # 设置输出文件路径 - 使用样本ID
    OUTPUT_FILE="\${OUTPUT_DIR}/\${SAMPLE_ID}_kraken2.output"
    REPORT_FILE="\${OUTPUT_DIR}/\${SAMPLE_ID}_kraken2.report"
    SAMPLE_LOG="\$LOG_DIR/\${SAMPLE_ID}_kraken2.log"
    
    echo "运行Kraken2: \$SAMPLE_ID" | tee -a "\$LOG_FILE"
    echo "输出文件将为: \$OUTPUT_FILE" | tee -a "\$LOG_FILE"
    echo "报告文件将为: \$REPORT_FILE" | tee -a "\$LOG_FILE"
    
    # 检查结果是否已存在
    if [ -f "\$REPORT_FILE" ] && [ -f "\$OUTPUT_FILE" ]; then
        echo "Kraken2结果已存在: \$SAMPLE_ID，跳过" | tee -a "\$LOG_FILE"
        continue
    fi
    
    # 运行Kraken2
    kraken2 --db "\$DATABASE_DIR" \\
        --output "\$OUTPUT_FILE" \\
        --report "\$REPORT_FILE" \\
        --threads "\$THREADS" \\
        --paired "\$FQ1" "\$FQ2" \\
        --use-names \\
        --report-zero-counts \\
        --confidence ${confidence} \\
        --memory-mapping \\
        --gzip-compressed \\
        --minimum-hit-groups ${min_hit_groups} 2>&1 | tee -a "\$SAMPLE_LOG"
    
    # 检查Kraken2是否成功
    if [ \$? -eq 0 ]; then
        echo "Kraken2完成: \$SAMPLE_ID" | tee -a "\$LOG_FILE"
    else
        echo "错误: Kraken2失败: \$SAMPLE_ID" | tee -a "\$LOG_FILE"
    fi
done

echo "${group_name}处理完成于: \$(date)" | tee -a "\$LOG_FILE"

EOF
        
        # 添加执行权限
        chmod +x "$script_file"
        log "INFO" "已创建脚本: $script_file"
    done
    
    # 创建并行执行脚本
    local parallel_script="${scripts_dir}/run_all_parallel.sh"
    
    cat > "$parallel_script" << EOF
#!/bin/bash

# 所有组的并行执行脚本
# 生成于: $(date)

# 最大并行作业数
MAX_PARALLEL=${DEFAULT_MAX_PARALLEL}

# 脚本目录
SCRIPTS_DIR="\$(dirname "\$0")"
LOG_DIR="${output_dir}/logs"
MAIN_LOG="\$LOG_DIR/parallel_execution.log"

mkdir -p "\$LOG_DIR"

echo "===== 开始并行处理所有组 =====" | tee -a "\$MAIN_LOG"
echo "最大并行作业数: \$MAX_PARALLEL" | tee -a "\$MAIN_LOG"
echo "开始时间: \$(date)" | tee -a "\$MAIN_LOG"

# 查找所有组处理脚本
GROUP_SCRIPTS=\$(find "\$SCRIPTS_DIR" -name "process_group*.sh" | sort)

# 并行运行脚本
for SCRIPT in \$GROUP_SCRIPTS; do
    # 检查当前运行的作业数
    RUNNING_JOBS=\$(jobs -p | wc -l)
    
    # 如果运行的最大作业数，等待任何作业完成
    while [ \$RUNNING_JOBS -ge \$MAX_PARALLEL ]; do
        sleep 10
        RUNNING_JOBS=\$(jobs -p | wc -l)
    done
    
    # 运行脚本
    GROUP_NAME=\$(basename "\$SCRIPT" .sh | sed 's/process_//')
    echo "启动\$GROUP_NAME处理(\$(date))" | tee -a "\$MAIN_LOG"
    bash "\$SCRIPT" &
done

# 等待所有组完成
echo "等待所有组完成..." | tee -a "\$MAIN_LOG"
wait

echo "所有处理完成于: \$(date)" | tee -a "\$MAIN_LOG"
EOF
    
    chmod +x "$parallel_script"
    log "INFO" "已创建并行执行脚本: $parallel_script"
    
    # 创建Bracken脚本
    local bracken_script="${scripts_dir}/run_bracken.sh"
    
    cat > "$bracken_script" << EOF
#!/bin/bash

# Bracken分析脚本 - 在所有Kraken2分析完成后运行
# 生成于: $(date)

# 设置路径
KRAKEN_DIR="${output_dir}"
BRACKEN_DIR="${output_dir%/*}/bracken"  # 修改为bracken目录
DATABASE_DIR="${database_dir}"
LOG_DIR="${output_dir}/logs"

# 设置参数
READ_LEN=${DEFAULT_READ_LENGTH}

# 日志文件
LOG_FILE="\$LOG_DIR/bracken_process.log"

echo "===== 开始Bracken分析 =====" | tee -a "\$LOG_FILE"
echo "开始时间: \$(date)" | tee -a "\$LOG_FILE"

# 为每个分类级别创建输出目录
LEVELS=("S" "G" "F" "O" "C" "P" "D")
LEVEL_NAMES=("species" "genus" "family" "order" "class" "phylum" "domain")

# 为每个级别创建目录
for LEVEL_NAME in "\${LEVEL_NAMES[@]}"; do
    mkdir -p "\${BRACKEN_DIR}/\${LEVEL_NAME}"
done

# 处理所有Kraken2报告文件
KRAKEN_REPORTS=\$(find "\$KRAKEN_DIR" -name "*_kraken2.report")

for REPORT_FILE in \$KRAKEN_REPORTS; do
    # 获取样本ID
    SAMPLE_ID=\$(basename "\$REPORT_FILE" _kraken2.report)
    echo "运行Bracken: \$SAMPLE_ID" | tee -a "\$LOG_FILE"
    
    # 为每个分类级别运行Bracken
    for i in "\${!LEVELS[@]}"; do
        LEVEL="\${LEVELS[\$i]}"
        LEVEL_NAME="\${LEVEL_NAMES[\$i]}"
        BRACKEN_OUT="\${BRACKEN_DIR}/\${LEVEL_NAME}/\${SAMPLE_ID}_bracken_\${LEVEL_NAME}.txt"
        
        # 检查结果是否已存在
        if [ -f "\$BRACKEN_OUT" ]; then
            echo "Bracken \$LEVEL_NAME结果已存在: \$SAMPLE_ID，跳过" | tee -a "\$LOG_FILE"
            continue
        fi
        
        # 运行Bracken
        bracken -d "\$DATABASE_DIR" \\
            -i "\$REPORT_FILE" \\
            -o "\$BRACKEN_OUT" \\
            -r "\$READ_LEN" \\
            -l "\$LEVEL" \\
            -t 0 2>&1 | tee -a "\${LOG_DIR}/\${SAMPLE_ID}_bracken_\${LEVEL_NAME}.log"
        
        # 检查Bracken是否成功
        if [ \$? -eq 0 ]; then
            echo "Bracken \$LEVEL_NAME完成: \$SAMPLE_ID" | tee -a "\$LOG_FILE"
        else
            echo "错误: Bracken \$LEVEL_NAME失败: \$SAMPLE_ID" | tee -a "\$LOG_FILE"
        fi
    done
done

# 尝试合并结果
COMBINE_SCRIPT=\$(which combine_bracken_outputs.py 2>/dev/null)
if [ -z "\$COMBINE_SCRIPT" ]; then
    echo "警告: 未找到combine_bracken_outputs.py脚本，跳过合并阶段" | tee -a "\$LOG_FILE"
else
    # 对每个分类级别合并结果
    for LEVEL_NAME in "\${LEVEL_NAMES[@]}"; do
        LEVEL_DIR="\${BRACKEN_DIR}/\${LEVEL_NAME}"
        COMBINED_OUT="\${BRACKEN_DIR}/combined_bracken_\${LEVEL_NAME}.txt"
        
        echo "合并\$LEVEL_NAME级别的Bracken结果" | tee -a "\$LOG_FILE"
        
        # 查找所有匹配的文件并保存到临时文件中
        FILE_LIST="\${LOG_DIR}/bracken_\${LEVEL_NAME}_files.txt"
        find "\$LEVEL_DIR" -name "*_bracken_\${LEVEL_NAME}.txt" > "\$FILE_LIST"
        
        # 检查是否找到了文件
        if [ ! -s "\$FILE_LIST" ]; then
            echo "警告: 未找到\${LEVEL_NAME}级别的Bracken结果文件，跳过合并" | tee -a "\$LOG_FILE"
            continue
        fi
        
        # 显示找到的文件
        FILE_COUNT=\$(wc -l < "\$FILE_LIST")
        echo "找到\$FILE_COUNT个\${LEVEL_NAME}级别的文件" | tee -a "\$LOG_FILE"
        
        # 构建文件参数列表
        FILES_ARG=""
        while IFS= read -r file; do
            FILES_ARG+="\\"\\"\$file\\"\\"\\ "
        done < "\$FILE_LIST"
        
        # 运行合并脚本
        eval python "\$COMBINE_SCRIPT" --files \$FILES_ARG --output "\$COMBINED_OUT" 2>&1 | tee -a "\${LOG_DIR}/combine_\${LEVEL_NAME}.log"
        
        if [ \$? -eq 0 ]; then
            echo "合并\$LEVEL_NAME完成: \$COMBINED_OUT" | tee -a "\$LOG_FILE"
        else
            echo "合并$LEVEL_NAME完成: $COMBINED_OUT" | tee -a "$LOG_FILE"
        else
            echo "错误: 合并$LEVEL_NAME失败" | tee -a "$LOG_FILE"
        fi
    done
fi

echo "Bracken分析完成于: $(date)" | tee -a "$LOG_FILE"
EOF
    
    chmod +x "$bracken_script"
    log "INFO" "已创建Bracken脚本: $bracken_script"
}

# 运行Kraken2分析
function run_kraken_analysis {
    local input_dir="$1"
    local output_dir="$2"
    local database_dir="$3"
    local max_parallel="$4"
    local threads="$5"
    local confidence="$6"
    local min_hit_groups="$7"
    local file_pattern="$8"
    
    if [ -z "$input_dir" ] || [ -z "$output_dir" ] || [ -z "$database_dir" ]; then
        log "ERROR" "Kraken2分析缺少必需参数"
        exit 1
    fi
    
    # 设置默认值
    if [ -z "$max_parallel" ]; then max_parallel=${DEFAULT_MAX_PARALLEL}; fi
    if [ -z "$threads" ]; then threads=${DEFAULT_THREADS}; fi
    if [ -z "$confidence" ]; then confidence=${DEFAULT_CONFIDENCE}; fi
    if [ -z "$min_hit_groups" ]; then min_hit_groups=${DEFAULT_MIN_HIT_GROUPS}; fi
    
    # 创建Kraken2脚本
    create_kraken_scripts "$input_dir" "$output_dir" "$database_dir" "$threads" "$confidence" "$min_hit_groups" "$file_pattern"
    
    local parallel_script="${output_dir}/scripts/run_all_parallel.sh"
    
    # 运行并行执行脚本
    log "INFO" "开始Kraken2分析，最多使用$max_parallel个并行作业..."
    sed -i "s/MAX_PARALLEL=.*/MAX_PARALLEL=${max_parallel}/" "$parallel_script"
    bash "$parallel_script"
    
    log "SUCCESS" "Kraken2分析完成。"
}


# Part 3
# 运行Bracken分析
function run_bracken_analysis {
    local input_dir="$1"
    local database_dir="$2"
    local read_len="$3"
    
    if [ -z "$input_dir" ] || [ -z "$database_dir" ]; then
        log "ERROR" "Bracken分析缺少必需参数"
        exit 1
    fi
    
    if [ -z "$read_len" ]; then read_len=${DEFAULT_READ_LENGTH}; fi
    
    local bracken_script="${input_dir}/scripts/run_bracken.sh"
    
    # 确保Bracken脚本存在
    if [ ! -f "$bracken_script" ]; then
        log "ERROR" "未找到Bracken脚本: $bracken_script"
        exit 1
    fi
    
    # 在Bracken脚本中更新读取长度
    sed -i "s/READ_LEN=.*/READ_LEN=${read_len}/" "$bracken_script"
    
    # 运行Bracken脚本
    log "INFO" "开始Bracken分析..."
    bash "$bracken_script"
    
    log "SUCCESS" "Bracken分析完成。"
}

# 生成MPA格式文件
function generate_mpa_format {
    local kraken_dir="$1"
    
    if [ -z "$kraken_dir" ]; then
        log "ERROR" "MPA格式生成缺少必需参数"
        exit 1
    fi
    
    local log_dir="${kraken_dir}/logs"
    mkdir -p "$log_dir"
    local log_file="${log_dir}/mpa_generation_$(date +%Y%m%d_%H%M%S).log"
    
    log "INFO" "开始MPA格式生成" | tee -a "$log_file"
    log "INFO" "Kraken2目录: $kraken_dir" | tee -a "$log_file"
    log "INFO" "输出目录: $kraken_dir" | tee -a "$log_file"
    log "INFO" "开始时间: $(date)" | tee -a "$log_file"
    
    # 创建Python脚本
    local python_script="${kraken_dir}/generate_combined_mpa.py"
    
    log "INFO" "创建Python处理脚本" | tee -a "$log_file"
    cat > "$python_script" << 'EOF'
#!/usr/bin/env python3
"""
从Kraken2报告生成合并的MPA格式文件
"""

import os
import sys
import glob
import argparse
from collections import defaultdict

def parse_kraken_report(report_file):
    """解析单个Kraken2报告文件并提取分类信息"""
    sample_name = os.path.basename(report_file).replace('_kraken2.report', '')
    taxonomy_dict = {}
    lineage_dict = {}
    
    # 分类级别代码映射
    rank_codes = {
        'D': 'k__',  # 域/超界
        'P': 'p__',  # 门
        'C': 'c__',  # 纲
        'O': 'o__',  # 目
        'F': 'f__',  # 科
        'G': 'g__',  # 属
        'S': 's__',  # 种
    }
    
    try:
        with open(report_file, 'r') as f:
            for line in f:
                parts = line.strip().split('\t')
                if len(parts) < 6:
                    continue
                    
                percentage = float(parts[0])
                reads = int(parts[1])
                rank_code = parts[3]
                taxid = parts[4]
                name = parts[5].lstrip()
                
                # 跳过未分类和根
                if taxid == '0' or taxid == '1':
                    continue
                    
                # 仅处理主要分类级别
                if rank_code in rank_codes:
                    taxonomy_dict[taxid] = {
                        'name': name,
                        'rank': rank_code,
                        'reads': reads,
                        'percentage': percentage
                    }
        
        # 第二次遍历构建完整的谱系
        with open(report_file, 'r') as f:
            current_lineage = []
            for line in f:
                parts = line.strip().split('\t')
                if len(parts) < 6:
                    continue
                    
                rank_code = parts[3]
                taxid = parts[4]
                name = parts[5].lstrip()
                indent = len(parts[5]) - len(name)
                
                # 跳过未分类和根
                if taxid == '0' or taxid == '1':
                    continue
                
                # 根据缩进调整当前谱系
                while len(current_lineage) > 0 and current_lineage[-1]['indent'] >= indent:
                    current_lineage.pop()
                
                # 添加当前分类
                current_entry = {
                    'taxid': taxid,
                    'name': name,
                    'rank': rank_code,
                    'indent': indent
                }
                current_lineage.append(current_entry)
                
                # 仅为主要分类级别构建谱系字符串
                if rank_code in rank_codes and taxid in taxonomy_dict:
                    lineage = []
                    for entry in current_lineage:
                        if entry['rank'] in rank_codes:
                            lineage.append(f"{rank_codes[entry['rank']]}{entry['name']}")
                    
                    if lineage:
                        lineage_str = '|'.join(lineage)
                        lineage_dict[lineage_str] = taxonomy_dict[taxid]['reads']
        
        return sample_name, lineage_dict
    
    except Exception as e:
        print(f"处理文件 {report_file} 时出错: {e}")
        return sample_name, {}

def generate_combined_mpa(kraken_dir, output_file):
    """从多个Kraken2报告生成合并的MPA格式文件"""
    # 获取所有Kraken2报告文件
    report_files = glob.glob(os.path.join(kraken_dir, '*_kraken2.report'))
    
    if not report_files:
        print(f"错误: 在{kraken_dir}中未找到任何Kraken2报告文件")
        return False
    
    print(f"找到 {len(report_files)} 个Kraken2报告文件")
    
    # 存储所有样本的数据
    all_data = defaultdict(dict)
    samples = []
    
    # 处理每个报告文件
    for report_file in sorted(report_files):
        try:
            sample_name, lineage_dict = parse_kraken_report(report_file)
            if sample_name and lineage_dict:
                samples.append(sample_name)
                
                # 添加该样本的数据
                for lineage, count in lineage_dict.items():
                    all_data[lineage][sample_name] = count
                
                print(f"成功处理样本: {sample_name}")
            else:
                print(f"警告: 样本 {os.path.basename(report_file)} 未返回有效数据")
        except Exception as e:
            print(f"处理文件 {report_file} 时出错: {e}")
    
    # 检查是否有任何样本数据
    if not samples:
        print("错误: 未找到任何有效样本数据")
        return False
    
    print(f"共处理了 {len(samples)} 个样本，找到 {len(all_data)} 个分类单元")
    
    # 写入合并文件
    try:
        with open(output_file, 'w') as out:
            # 写入标题行
            out.write('#Classification\t' + '\t'.join(samples) + '\n')
            
            # 写入数据行
            for lineage in sorted(all_data.keys()):
                row = [lineage]
                for sample in samples:
                    row.append(str(all_data[lineage].get(sample, 0)))
                out.write('\t'.join(row) + '\n')
        
        print(f"成功创建合并文件: {output_file}")
        return True
    except Exception as e:
        print(f"创建合并文件时出错: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description='从Kraken2报告生成合并的MPA格式文件')
    parser.add_argument('-i', '--input', required=True, help='包含Kraken2报告的目录')
    parser.add_argument('-o', '--output', required=True, help='输出合并MPA文件的路径')
    args = parser.parse_args()
    
    if generate_combined_mpa(args.input, args.output):
        print("成功生成合并的MPA格式文件")
        return 0
    else:
        print("生成合并的MPA格式文件失败")
        return 1

if __name__ == '__main__':
    sys.exit(main())
EOF
    
    # 添加执行权限
    chmod +x "$python_script"
    
    # 备份当前的合并文件
    local mpa_file="${kraken_dir}/combined_mpa.txt"
    if [ -f "$mpa_file" ]; then
        log "INFO" "备份当前的合并文件" | tee -a "$log_file"
        mv "$mpa_file" "${mpa_file}.bak.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # 运行Python脚本生成MPA文件
    log "INFO" "开始生成MPA文件..." | tee -a "$log_file"
    python3 "$python_script" -i "$kraken_dir" -o "$mpa_file" 2>&1 | tee -a "$log_file"
    
    # 检查结果
    if [ -f "$mpa_file" ]; then
        log "INFO" "合并MPA文件创建成功" | tee -a "$log_file"
        
        # 获取文件大小
        local file_size=$(du -h "$mpa_file" | cut -f1)
        log "INFO" "合并文件大小: $file_size" | tee -a "$log_file"
        
        # 获取样本数和分类单元数
        local header=$(head -1 "$mpa_file")
        local sample_count=$(echo "$header" | awk -F'\t' '{print NF-1}')
        local taxonomy_count=$(wc -l < "$mpa_file")
        
        log "INFO" "合并文件包含 $sample_count 个样本和 $((taxonomy_count-1)) 个分类单元" | tee -a "$log_file"
    else
        log "ERROR" "合并MPA文件创建失败" | tee -a "$log_file"
        return 1
    fi
    
    log "SUCCESS" "MPA格式生成完成于: $(date)" | tee -a "$log_file"
    return 0
}


# Part 4
# 增强Bracken结果
function enhance_bracken_results {
    local kraken_dir="$1"
    
    if [ -z "$kraken_dir" ]; then
        log "ERROR" "增强Bracken结果缺少必需参数"
        exit 1
    fi
    
    # 获取MPA文件路径
    local mpa_file="${kraken_dir}/combined_mpa.txt"
    
    # 获取bracken和enhanced目录
    local base_dir=$(dirname "$kraken_dir")
    local bracken_dir="${base_dir}/bracken"
    local output_dir="${bracken_dir}/enhanced"
    
    if [ ! -f "$mpa_file" ]; then
        log "ERROR" "MPA文件不存在: $mpa_file"
        exit 1
    fi
    
    local log_dir="${output_dir}/logs"
    mkdir -p "$log_dir"
    local log_file="${log_dir}/enhance_bracken_$(date +%Y%m%d_%H%M%S).log"
    
    log "INFO" "开始增强Bracken结果文件" | tee -a "$log_file"
    log "INFO" "MPA文件: $mpa_file" | tee -a "$log_file"
    log "INFO" "Bracken目录: $bracken_dir" | tee -a "$log_file"
    log "INFO" "输出目录: $output_dir" | tee -a "$log_file"
    log "INFO" "开始时间: $(date)" | tee -a "$log_file"
    
    # 创建Python脚本
    local python_script="${output_dir}/enhance_bracken.py"
    
    log "INFO" "创建Python处理脚本" | tee -a "$log_file"
    cat > "$python_script" << 'EOF'
#!/usr/bin/env python3
"""
将MPA格式的分类信息添加到Bracken合并结果文件中
但只包含到对应级别的分类信息
"""

import os
import sys
import argparse
import pandas as pd
from collections import defaultdict

def parse_mpa_file(mpa_file):
    """解析MPA文件，提取分类信息"""
    taxonomy_map = {}
    taxonomy_levels = {
        'k__': 'domain',
        'p__': 'phylum',
        'c__': 'class', 
        'o__': 'order',
        'f__': 'family',
        'g__': 'genus',
        's__': 'species'
    }
    
    with open(mpa_file, 'r') as f:
        next(f)  # 跳过标题行
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) < 2:
                continue
            
            lineage = parts[0]
            lineage_parts = lineage.split('|')
            
            # 获取该行的最后一个分类单元
            last_part = lineage_parts[-1]
            for prefix, level in taxonomy_levels.items():
                if last_part.startswith(prefix):
                    # 提取名称和级别
                    name = last_part[len(prefix):]
                    tax_level = level
                    
                    # 构建完整分类谱系字典
                    full_taxonomy = {}
                    for part in lineage_parts:
                        for p, l in taxonomy_levels.items():
                            if part.startswith(p):
                                full_taxonomy[l] = part[len(p):]
                                break
                    
                    # 保存数据，使用名称和税号作为键 (适配Bracken输出)
                    if name:
                        taxonomy_map[name] = full_taxonomy
                    
                    break
    
    return taxonomy_map

def enhance_bracken_file(bracken_file, taxonomy_map, output_file, level):
    """增强Bracken文件，只添加到对应级别的分类信息"""
    try:
        # 分类级别对应的列名和索引
        level_columns = {
            'domain': 'Domain',
            'phylum': 'Phylum',
            'class': 'Class',
            'order': 'Order',
            'family': 'Family',
            'genus': 'Genus',
            'species': 'Species'
        }
        
        # 级别索引，用于确定显示哪些列
        level_indices = {
            'domain': 0,
            'phylum': 1,
            'class': 2,
            'order': 3,
            'family': 4,
            'genus': 5,
            'species': 6
        }
        
        # 验证级别
        if level not in level_indices:
            print(f"错误: 无效的分类级别 '{level}'")
            return False
        
        # 获取当前级别索引
        current_index = level_indices[level]
        
        # 读取Bracken文件
        df = pd.read_csv(bracken_file, sep='\t')
        
        # 只创建到当前级别的列
        for l, col_name in level_columns.items():
            if level_indices[l] <= current_index:
                df[col_name] = ""
        
        # 填充分类信息
        for index, row in df.iterrows():
            name = row['name']
            
            # 对于非物种级别，尝试直接匹配
            if level != 'species' and name in taxonomy_map:
                tax_info = taxonomy_map[name]
                for l, col_name in level_columns.items():
                    if level_indices[l] <= current_index and l in tax_info:
                        df.at[index, col_name] = tax_info[l]
            else:
                # 尝试找到匹配的分类信息
                found = False
                
                # 对于物种级别，直接查找
                if level == 'species' and name in taxonomy_map:
                    tax_info = taxonomy_map[name]
                    for l, col_name in level_columns.items():
                        if level_indices[l] <= current_index and l in tax_info:
                            df.at[index, col_name] = tax_info[l]
                    found = True
                
                # 对于其他级别，使用部分匹配
                if not found and level != 'species':
                    for tax_name, tax_info in taxonomy_map.items():
                        if level in tax_info and tax_info[level] == name:
                            for l, col_name in level_columns.items():
                                if level_indices[l] <= current_index and l in tax_info:
                                    df.at[index, col_name] = tax_info[l]
                            found = True
                            break
        
        # 重新排列列，将分类信息放在前面
        cols = df.columns.tolist()
        taxonomy_cols = [level_columns[l] for l in level_columns if level_indices[l] <= current_index]
        other_cols = [c for c in cols if c not in list(level_columns.values())]
        new_cols = taxonomy_cols + other_cols
        
        # 保存结果
        df = df[new_cols]
        df.to_csv(output_file, sep='\t', index=False)
        
        print(f"已创建增强版文件，只包含到 {level} 级别的分类信息")
        return True
    except Exception as e:
        print(f"错误处理文件 {bracken_file}: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description='增强Bracken结果文件，添加完整分类信息')
    parser.add_argument('-m', '--mpa', required=True, help='MPA格式文件')
    parser.add_argument('-b', '--bracken', required=True, help='Bracken合并结果文件')
    parser.add_argument('-o', '--output', required=True, help='输出文件')
    parser.add_argument('-l', '--level', required=True, help='分类级别')
    args = parser.parse_args()
    
    # 解析MPA文件
    print(f"解析MPA文件: {args.mpa}")
    taxonomy_map = parse_mpa_file(args.mpa)
    print(f"提取了 {len(taxonomy_map)} 个分类单元的信息")
    
    # 增强Bracken文件
    print(f"处理Bracken文件: {args.bracken}")
    result = enhance_bracken_file(args.bracken, taxonomy_map, args.output, args.level)
    
    if result:
        print(f"成功创建增强版结果文件: {args.output}")
    else:
        print(f"处理失败")
        return 1
    
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOF
    
    # 添加执行权限
    chmod +x "$python_script"
    
    # 创建输出目录
    mkdir -p "$output_dir"
    
    # 分类级别及对应的合并文件
    declare -A level_files
    level_files=(
        ["species"]="${bracken_dir}/combined_bracken_species.txt"
        ["genus"]="${bracken_dir}/combined_bracken_genus.txt"
        ["family"]="${bracken_dir}/combined_bracken_family.txt"
        ["order"]="${bracken_dir}/combined_bracken_order.txt"
        ["class"]="${bracken_dir}/combined_bracken_class.txt"
        ["phylum"]="${bracken_dir}/combined_bracken_phylum.txt"
        ["domain"]="${bracken_dir}/combined_bracken_domain.txt"
    )
    
    # 处理每个分类级别的Bracken结果
    for level in "${!level_files[@]}"; do
        local bracken_file="${level_files[$level]}"
        
        # 检查文件是否存在
        if [ ! -f "$bracken_file" ]; then
            log "WARN" "Bracken结果文件不存在 ($bracken_file)" | tee -a "$log_file"
            continue
        fi
        
        local enhanced_file="${output_dir}/enhanced_bracken_${level}.txt"
        log "INFO" "处理 $level 级别的Bracken结果" | tee -a "$log_file"
        
        # 运行Python脚本增强Bracken结果
        python3 "$python_script" \
            -m "$mpa_file" \
            -b "$bracken_file" \
            -o "$enhanced_file" \
            -l "$level" 2>&1 | tee -a "${log_dir}/enhance_${level}.log"
        
        if [ $? -eq 0 ]; then
            log "INFO" "成功创建增强版 $level 结果: $enhanced_file" | tee -a "$log_file"
        else
            log "ERROR" "处理 $level 级别失败" | tee -a "$log_file"
        fi
    done
    
    log "SUCCESS" "增强Bracken结果完成" | tee -a "$log_file"
    log "INFO" "结果保存在: $output_dir" | tee -a "$log_file"
    log "INFO" "完成时间: $(date)" | tee -a "$log_file"
    
    return 0
}

# 运行完整工作流程
function run_complete_workflow {
    local base_dir="$1"
    local raw_data_dir="$2"
    local database_dir="$3"
    local group_size="$4"
    local max_parallel="$5"
    local threads="$6"
    local read_len="$7"
    local confidence="$8"
    local min_hit_groups="$9"
    local r1_pattern="${10}"
    local r2_pattern="${11}"
    
    # 验证必需的参数
    if [ -z "$base_dir" ] || [ -z "$raw_data_dir" ] || [ -z "$database_dir" ]; then
        log "ERROR" "完整工作流程缺少必需参数"
        exit 1
    fi
    
    # 设置默认值
    if [ -z "$group_size" ]; then group_size=${DEFAULT_GROUP_SIZE}; fi
    if [ -z "$max_parallel" ]; then max_parallel=${DEFAULT_MAX_PARALLEL}; fi
    if [ -z "$threads" ]; then threads=${DEFAULT_THREADS}; fi
    if [ -z "$read_len" ]; then read_len=${DEFAULT_READ_LENGTH}; fi
    if [ -z "$confidence" ]; then confidence=${DEFAULT_CONFIDENCE}; fi
    if [ -z "$min_hit_groups" ]; then min_hit_groups=${DEFAULT_MIN_HIT_GROUPS}; fi
    
    # 设置目录路径
    local grouped_dir="${base_dir}/2.cleandata/grouped"
    local kraken_dir="${base_dir}/5.annotation/kraken2"
    local bracken_dir="${base_dir}/5.annotation/bracken"
    
    # 创建目录结构
    log "INFO" "步骤0: 创建目录结构..."
    setup_directories "$base_dir"
    
    # 分组样本
    log "INFO" "步骤1: 对样本进行分组..."
    group_samples "$raw_data_dir" "$grouped_dir" "$group_size" "$r1_pattern" "$r2_pattern"
    
    # 运行Kraken2分析
    log "INFO" "步骤2: 运行Kraken2分析..."
    run_kraken_analysis "$grouped_dir" "$kraken_dir" "$database_dir" "$max_parallel" "$threads" "$confidence" "$min_hit_groups" "$r1_pattern"
    
    # 运行Bracken分析
    log "INFO" "步骤3: 运行Bracken分析..."
    run_bracken_analysis "$kraken_dir" "$database_dir" "$read_len"
    
    # 生成MPA格式文件
    log "INFO" "步骤4: 生成MPA格式文件..."
    generate_mpa_format "$kraken_dir"
    
    # 增强Bracken结果
    log "INFO" "步骤5: 增强Bracken结果..."
    enhance_bracken_results "$kraken_dir"
    
    log "SUCCESS" "完整工作流程执行完成。"
    log "INFO" "结果保存在:"
    log "INFO" "  - Kraken2结果: $kraken_dir"
    log "INFO" "  - MPA格式文件: ${kraken_dir}/combined_mpa.txt"
    log "INFO" "  - Bracken结果: ${bracken_dir}"
    log "INFO" "  - 增强结果: ${bracken_dir}/enhanced"
}


# Part 5

# 主函数
function main {
    # 如果没有参数，显示帮助
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi
    
    # 验证依赖项
    check_dependencies
    
    # 处理第一个参数（命令）
    local command="$1"
    shift
    
    # 根据命令执行相应的函数
    case "$command" in
        setup)
            local base_dir=""
            
            # 解析参数
            while [ $# -gt 0 ]; do
                case "$1" in
                    -h|--help)
                        show_usage
                        exit 0
                        ;;
                    -d|--dir)
                        base_dir="$2"
                        shift 2
                        ;;
                    *)
                        log "ERROR" "未知参数: $1"
                        exit 1
                        ;;
                esac
            done
            
            # 验证必需的参数
            if [ -z "$base_dir" ]; then
                log "ERROR" "缺少必需参数: -d/--dir"
                exit 1
            fi
            
            # 执行函数
            setup_directories "$base_dir"
            ;;
            
        group)
            local input_dir=""
            local output_dir=""
            local group_size=$DEFAULT_GROUP_SIZE
            local r1_pattern=""
            local r2_pattern=""
            
            # 解析参数
            while [ $# -gt 0 ]; do
                case "$1" in
                    -h|--help)
                        show_usage
                        exit 0
                        ;;
                    -i|--input)
                        input_dir="$2"
                        shift 2
                        ;;
                    -o|--output)
                        output_dir="$2"
                        shift 2
                        ;;
                    -s|--size)
                        group_size="$2"
                        shift 2
                        ;;
                    --r1-pattern)
                        r1_pattern="$2"
                        shift 2
                        ;;
                    --r2-pattern)
                        r2_pattern="$2"
                        shift 2
                        ;;
                    *)
                        log "ERROR" "未知参数: $1"
                        exit 1
                        ;;
                esac
            done
            
            # 验证必需的参数
            if [ -z "$input_dir" ] || [ -z "$output_dir" ]; then
                log "ERROR" "缺少必需参数: -i/--input 和/或 -o/--output"
                exit 1
            fi
            
            # 执行函数
            group_samples "$input_dir" "$output_dir" "$group_size" "$r1_pattern" "$r2_pattern"
            ;;
            
        kraken)
            local input_dir=""
            local output_dir=""
            local database_dir=""
            local max_parallel=$DEFAULT_MAX_PARALLEL
            local threads=$DEFAULT_THREADS
            local confidence=$DEFAULT_CONFIDENCE
            local min_hit_groups=$DEFAULT_MIN_HIT_GROUPS
            local r1_pattern=""
            
            # 解析参数
            while [ $# -gt 0 ]; do
                case "$1" in
                    -h|--help)
                        show_usage
                        exit 0
                        ;;
                    -i|--input)
                        input_dir="$2"
                        shift 2
                        ;;
                    -o|--output)
                        output_dir="$2"
                        shift 2
                        ;;
                    -d|--database)
                        database_dir="$2"
                        shift 2
                        ;;
                    -p|--parallel)
                        max_parallel="$2"
                        shift 2
                        ;;
                    -t|--threads)
                        threads="$2"
                        shift 2
                        ;;
                    -c|--confidence)
                        confidence="$2"
                        shift 2
                        ;;
                    -m|--min-hits)
                        min_hit_groups="$2"
                        shift 2
                        ;;
                    --r1-pattern)
                        r1_pattern="$2"
                        shift 2
                        ;;
                    *)
                        log "ERROR" "未知参数: $1"
                        exit 1
                        ;;
                esac
            done
            
            # 验证必需的参数
            if [ -z "$input_dir" ] || [ -z "$output_dir" ] || [ -z "$database_dir" ]; then
                log "ERROR" "缺少必需参数: -i/--input, -o/--output 和/或 -d/--database"
                exit 1
            fi
            
            # 执行函数
            run_kraken_analysis "$input_dir" "$output_dir" "$database_dir" "$max_parallel" "$threads" "$confidence" "$min_hit_groups" "$r1_pattern"
            ;;
            
        bracken)
            local input_dir=""
            local database_dir=""
            local read_len=$DEFAULT_READ_LENGTH
            
            # 解析参数
            while [ $# -gt 0 ]; do
                case "$1" in
                    -h|--help)
                        show_usage
                        exit 0
                        ;;
                    -i|--input)
                        input_dir="$2"
                        shift 2
                        ;;
                    -d|--database)
                        database_dir="$2"
                        shift 2
                        ;;
                    -r|--read-len)
                        read_len="$2"
                        shift 2
                        ;;
                    *)
                        log "ERROR" "未知参数: $1"
                        exit 1
                        ;;
                esac
            done
            
            # 验证必需的参数
            if [ -z "$input_dir" ] || [ -z "$database_dir" ]; then
                log "ERROR" "缺少必需参数: -i/--input 和/或 -d/--database"
                exit 1
            fi
            
            # 执行函数
            run_bracken_analysis "$input_dir" "$database_dir" "$read_len"
            ;;
            
        mpa)
            local kraken_dir=""
            
            # 解析参数
            while [ $# -gt 0 ]; do
                case "$1" in
                    -h|--help)
                        show_usage
                        exit 0
                        ;;
                    -k|--kraken)
                        kraken_dir="$2"
                        shift 2
                        ;;
                    *)
                        log "ERROR" "未知参数: $1"
                        exit 1
                        ;;
                esac
            done
            
            # 验证必需的参数
            if [ -z "$kraken_dir" ]; then
                log "ERROR" "缺少必需参数: -k/--kraken"
                exit 1
            fi
            
            # 执行函数
            generate_mpa_format "$kraken_dir"
            ;;
            
        enhance)
            local kraken_dir=""
            
            # 解析参数
            while [ $# -gt 0 ]; do
                case "$1" in
                    -h|--help)
                        show_usage
                        exit 0
                        ;;
                    -k|--kraken)
                        kraken_dir="$2"
                        shift 2
                        ;;
                    *)
                        log "ERROR" "未知参数: $1"
                        exit 1
                        ;;
                esac
            done
            
            # 验证必需的参数
            if [ -z "$kraken_dir" ]; then
                log "ERROR" "缺少必需参数: -k/--kraken"
                exit 1
            fi
            
            # 执行函数
            enhance_bracken_results "$kraken_dir"
            ;;
            
        all)
            local base_dir=""
            local raw_data_dir=""
            local database_dir=""
            local group_size=$DEFAULT_GROUP_SIZE
            local max_parallel=$DEFAULT_MAX_PARALLEL
            local threads=$DEFAULT_THREADS
            local read_len=$DEFAULT_READ_LENGTH
            local confidence=$DEFAULT_CONFIDENCE
            local min_hit_groups=$DEFAULT_MIN_HIT_GROUPS
            local r1_pattern=""
            local r2_pattern=""
            
            # 解析参数
            while [ $# -gt 0 ]; do
                case "$1" in
                    -h|--help)
                        show_usage
                        exit 0
                        ;;
                    -d|--dir)
                        base_dir="$2"
                        shift 2
                        ;;
                    -i|--input)
                        raw_data_dir="$2"
                        shift 2
                        ;;
                    -b|--database)
                        database_dir="$2"
                        shift 2
                        ;;
                    -s|--size)
                        group_size="$2"
                        shift 2
                        ;;
                    -p|--parallel)
                        max_parallel="$2"
                        shift 2
                        ;;
                    -t|--threads)
                        threads="$2"
                        shift 2
                        ;;
                    -r|--read-len)
                        read_len="$2"
                        shift 2
                        ;;
                    -c|--confidence)
                        confidence="$2"
                        shift 2
                        ;;
                    -m|--min-hits)
                        min_hit_groups="$2"
                        shift 2
                        ;;
                    --r1-pattern)
                        r1_pattern="$2"
                        shift 2
                        ;;
                    --r2-pattern)
                        r2_pattern="$2"
                        shift 2
                        ;;
                    *)
                        log "ERROR" "未知参数: $1"
                        exit 1
                        ;;
                esac
            done
            
            # 验证必需的参数
            if [ -z "$base_dir" ] || [ -z "$raw_data_dir" ] || [ -z "$database_dir" ]; then
                log "ERROR" "缺少必需参数: -d/--dir, -i/--input 和/或 -b/--database"
                exit 1
            fi
            
            # 执行函数
            run_complete_workflow "$base_dir" "$raw_data_dir" "$database_dir" "$group_size" "$max_parallel" "$threads" "$read_len" "$confidence" "$min_hit_groups" "$r1_pattern" "$r2_pattern"
            ;;
            
        -v|--version)
            show_version
            ;;
            
        -h|--help)
            show_usage
            ;;
            
        *)
            log "ERROR" "未知命令: $command"
            show_usage
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
