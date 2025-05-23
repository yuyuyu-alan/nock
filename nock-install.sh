#!/bin/bash

# ========= 色彩定义 =========
RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'

# ========= 项目路径 =========
NCK_DIR="$HOME/nockchain"

# ========= 横幅与署名 =========
function show_banner() {
  clear
  echo -e "${BOLD}${BLUE}"
  echo "               ╔═╗╔═╦╗─╔╦═══╦═══╦═══╦═══╗"
  echo "               ╚╗╚╝╔╣║─║║╔══╣╔═╗║╔═╗║╔═╗║"
  echo "               ─╚╗╔╝║║─║║╚══╣║─╚╣║─║║║─║║"
  echo "               ─╔╝╚╗║║─║║╔══╣║╔═╣╚═╝║║─║║"
  echo "               ╔╝╔╗╚╣╚═╝║╚══╣╚╩═║╔═╗║╚═╝║"
  echo "               ╚═╝╚═╩═══╩═══╩═══╩╝─╚╩═══╝"
  echo -e "${RESET}"
  echo "               关注TG频道：t.me/xuegaoz"
  echo "               我的GitHub：github.com/Gzgod"
  echo "               我的推特：推特雪糕战神@Xuegaogx"
  echo "-----------------------------------------------"
  echo ""
}

# ========= 等待任意键继续 =========
function pause_and_return() {
  echo ""
  read -n1 -r -p "按任意键返回主菜单..." key
  main_menu
}

# ========= 启动节点（Miner 或非 Miner） =========
function start_node() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain 目录不存在，请先运行选项 3！${RESET}"
    pause_and_return
    return
  fi
  cd "$NCK_DIR" || { echo -e "${RED}[-] 无法进入 nockchain 目录！${RESET}"; pause_and_return; return; }

  # 验证 nockchain 命令是否可用
  echo -e "[*] 正在验证 nockchain 命令..."
  if ! command -v nockchain &> /dev/null; then
    echo -e "${RED}[-] nockchain 命令不可用，请检查选项 4 是否成功！${RESET}"
    echo -e "${YELLOW}[!] 请确保 \$PATH 包含 $HOME/.cargo/bin，可运行 'source ~/.bashrc' 或重新打开终端${RESET}"
    pause_and_return
    return
  fi

  # 验证 screen 命令是否可用
  echo -e "[*] 正在验证 screen 命令..."
  if ! command -v screen &> /dev/null; then
    echo -e "${RED}[-] screen 命令不可用，请确保已安装 screen（运行选项 1 或手动安装）！${RESET}"
    pause_and_return
    return
  fi

  # 选择节点类型
  echo -e "[*] 请选择节点类型："
  echo -e "  1) Miner 节点（挖矿）"
  echo -e "  2) 非 Miner 节点（仅运行节点）"
  read -p "[?] 请输入编号 (1/2): " node_type
  if [[ "$node_type" != "1" && "$node_type" != "2" ]]; then
    echo -e "${RED}[-] 无效选项，请选择 1 或 2！${RESET}"
    pause_and_return
    return
  fi

  # 设置工作目录
  echo -e "[*] 输入节点工作目录（默认：$NCK_DIR）..."
  read -p "[?] 工作目录 [$NCK_DIR]: " work_dir
  work_dir=${work_dir:-$NCK_DIR}
  if [ ! -d "$work_dir" ]; then
    echo -e "[*] 创建工作目录 $work_dir..."
    mkdir -p "$work_dir" || { echo -e "${RED}[-] 无法创建工作目录！${RESET}"; pause_and_return; return; }
    cp "$NCK_DIR/.env" "$work_dir/.env" 2>/dev/null || echo -e "${YELLOW}[!] 未找到 .env 文件，请确保已运行选项 3！${RESET}"
  fi
  cd "$work_dir" || { echo -e "${RED}[-] 无法进入工作目录 $work_dir！${RESET}"; pause_and_return; return; }

  # 如果是 Miner 节点，获取公钥
  public_key=""
  if [ "$node_type" = "1" ]; then
    if [ -f ".env" ]; then
      public_key=$(grep "^MINING_PUBKEY=" .env | cut -d'=' -f2)
      if [ -z "$public_key" ]; then
        echo -e "${YELLOW}[!] .env 文件中未找到 MINING_PUBKEY，请使用选项 6 设置或手动输入。${RESET}"
        read -p "[?] 请输入您的 MINING_PUBKEY（可从选项 5 获取）： " public_key
        if [ -z "$public_key" ]; then
          echo -e "${RED}[-] 未提供 MINING_PUBKEY，请输入有效的公钥！${RESET}"
          pause_and_return
          return
        fi
      else
        echo -e "[*] 使用 .env 文件中的 MINING_PUBKEY：$public_key"
      fi
    else
      echo -e "${YELLOW}[!] .env 文件不存在，请使用选项 6 设置或手动输入 MINING_PUBKEY。${RESET}"
      read -p "[?] 请输入您的 MINING_PUBKEY（可从选项 5 获取）： " public_key
      if [ -z "$public_key" ]; then
        echo -e "${RED}[-] 未提供 MINING_PUBKEY，请输入有效的公钥！${RESET}"
        pause_and_return
        return
      fi
    fi
  fi

  # 提示清理数据目录
  if [ -d ".data.nockchain" ]; then
    echo -e "${YELLOW}[?] 检测到数据目录 .data.nockchain，是否清理以重新初始化？(y/n)${RESET}"
    read -r confirm_clean
    if [[ "$confirm_clean" == "y" || "$confirm_clean" == "Y" ]]; then
      echo -e "[*] 备份并清理数据目录..."
      mv .data.nockchain .data.nockchain.bak-$(date +%F-%H%M%S) 2>/dev/null
      echo -e "${GREEN}[+] 数据目录已清理，备份至 .data.nockchain.bak-*${RESET}"
    fi
  fi

  # 设置端口
  echo -e "[*] 输入节点端口（默认 Leader: 3005, Follower: 3006）..."
  read -p "[?] Leader 端口 [3005]: " LEADER_PORT
  LEADER_PORT=${LEADER_PORT:-3005}
  read -p "[?] Follower 端口 [3006]: " FOLLOWER_PORT
  FOLLOWER_PORT=${FOLLOWER_PORT:-3006}
  PORTS_TO_CHECK=("$LEADER_PORT" "$FOLLOWER_PORT")
  PORTS_OCCUPIED=false
  declare -A PID_PORT_MAP

  # 设置绑定地址
  echo -e "[*] 输入 P2P 绑定地址（例如 /ip4/0.0.0.0/udp/$FOLLOWER_PORT/quic-v1，若 NAT 后请输入公网 IP）..."
  read -p "[?] 绑定地址 [/ip4/0.0.0.0/udp/$FOLLOWER_PORT/quic-v1]: " bind_addr
  bind_addr=${bind_addr:-/ip4/0.0.0.0/udp/$FOLLOWER_PORT/quic-v1}

  # 检查端口占用
  echo -e "[*] 检查端口 $LEADER_PORT 和 $FOLLOWER_PORT 是否被占用..."
  if command -v lsof &> /dev/null; then
    for PORT in "${PORTS_TO_CHECK[@]}"; do
      PIDS=$(lsof -i :$PORT -t | sort -u)
      if [ -n "$PIDS" ]; then
        echo -e "${YELLOW}[!] 端口 $PORT 已被占用。${RESET}"
        for PID in $PIDS; do
          echo -e "${YELLOW}[!] 占用端口 $PORT 的进程 PID: $PID${RESET}"
          PID_PORT_MAP[$PID]+="$PORT "
          PORTS_OCCUPIED=true
        done
      fi
    done
  elif command -v netstat &> /dev/null; then
    for PORT in "${PORTS_TO_CHECK[@]}"; do
      PIDS=$(netstat -tulnp 2>/dev/null | grep ":$PORT " | awk '{print $7}' | cut -d'/' -f1 | sort -u)
      if [ -n "$PIDS" ]; then
        echo -e "${YELLOW}[!] 端口 $PORT 已被占用。${RESET}"
        for PID in $PIDS; do
          echo -e "${YELLOW}[!] 占用端口 $PORT 的进程 PID: $PID${RESET}"
          PID_PORT_MAP[$PID]+="$PORT "
          PORTS_OCCUPIED=true
        done
      fi
    done
  else
    echo -e "${RED}[-] 未找到 lsof 或 netstat 命令，无法检查端口！${RESET}"
    pause_and_return
    return
  fi

  # 处理端口占用
  if [ "$PORTS_OCCUPIED" = true ]; then
    echo -e "${YELLOW}[?] 检测到端口被占用，是否杀死占用进程以释放端口？(y/n)${RESET}"
    read -r confirm_kill
    if [[ "$confirm_kill" == "y" || "$confirm_kill" == "Y" ]]; then
      for PID in "${!PID_PORT_MAP[@]}"; do
        PORTS=${PID_PORT_MAP[$PID]}
        echo -e "[*] 正在杀死占用端口 $PORTS 的进程 (PID: $PID)..."
        if ! ps -p "$PID" -o user= | grep -q "^$USER$"; then
          echo -e "${YELLOW}[!] 进程 PID $PID 由其他用户拥有，尝试使用 sudo 杀死...${RESET}"
          sudo kill -9 "$PID" 2>/dev/null
        else
          kill -9 "$PID" 2>/dev/null
        fi
        if [ $? -eq 0 ]; then
          echo -e "${GREEN}[+] 成功杀死 PID $PID，端口 $PORTS 应已释放。${RESET}"
        else
          echo -e "${RED}[-] 无法杀死 PID $PID，请手动检查！${RESET}"
          pause_and_return
          return
        fi
      done
      echo -e "[*] 验证端口是否已释放..."
      for PORT in "${PORTS_TO_CHECK[@]}"; do
        if command -v lsof &> /dev/null && lsof -i :$PORT -t >/dev/null 2>&1; then
          echo -e "${RED}[-] 端口 $PORT 仍被占用，请手动检查！${RESET}"
          pause_and_return
          return
        elif command -v netstat &> /dev/null && netstat -tuln | grep -q ":$PORT "; then
          echo -e "${RED}[-] 端口 $PORT 仍被占用，请手动检查！${RESET}"
          pause_and_return
          return
        fi
      done
    else
      echo -e "${RED}[-] 用户取消杀死进程，无法启动节点！${RESET}"
      pause_and_return
      return
    fi
  else
    echo -e "${GREEN}[+] 端口 $LEADER_PORT 和 $FOLLOWER_PORT 未被占用。${RESET}"
  fi

  # 设置日志级别
  echo -e "[*] 请选择日志级别："
  echo -e "  1) info（推荐，常规信息）"
  echo -e "  2) debug（调试信息）"
  echo -e "  3) trace（详细调试信息）"
  read -p "[?] 请输入编号 (1/2/3) [1]: " log_level_choice
  case "$log_level_choice" in
    2) log_level="debug" ;;
    3) log_level="trace" ;;
    *) log_level="info" ;;
  esac
  if [ -f ".env" ]; then
    if ! grep -q "^RUST_LOG=" .env; then
      echo "RUST_LOG=$log_level" >> .env
    else
      sed -i "s|^RUST_LOG=.*|RUST_LOG=$log_level|" .env
    fi
  fi
  echo -e "[*] 日志级别设置为：$log_level"

  # 询问是否输出 miner.log
  echo -e "${YELLOW}[?] 是否输出 miner.log 日志文件？（警告：日志文件可能占用较大磁盘空间，请谨慎选择！）[y/N]${RESET}"
  read -r log_to_file
  log_to_file=${log_to_file:-n}
  if [[ "$log_to_file" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}[+] 将输出日志到 $work_dir/miner.log，请定期清理以避免磁盘空间不足！${RESET}"
    log_output="2>&1 | tee -a miner.log"
  else
    echo -e "${YELLOW}[!] 已选择不输出 miner.log，日志仅保存在 screen 日志 $work_dir/screen_$session_name.log 中${RESET}"
    log_output="2>&1"
  fi

  # 清理现有的 screen 会话
  echo -e "[*] 正在清理现有的 $session_name screen 会话..."
  screen -ls | grep -q "$session_name" && screen -X -S "$session_name" quit

  # 启动节点
  echo -e "[*] 正在启动节点..."
  if [ "$node_type" = "1" ]; then
    script="$NCK_DIR/scripts/run_nockchain_miner.sh"
    session_name="miner"
  else
    script="$NCK_DIR/scripts/run_nockchain_node.sh"
    session_name="node"
  fi
  if [ ! -f "$script" ]; then
    echo -e "${RED}[-] 未找到 $script，请检查 nockchain 仓库！${RESET}"
    pause_and_return
    return
  fi
  chmod +x "$script"
  echo -e "${GREEN}[+] 启动节点在 screen 会话 '$session_name' 中，screen 日志输出到 $work_dir/screen_$session_name.log${RESET}"
  echo -e "${YELLOW}[!] 使用 'screen -r $session_name' 查看节点实时输出，Ctrl+A 然后 D 脱离 screen（节点继续运行）${RESET}"
  screen -dmS "$session_name" -L -Logfile "$work_dir/screen_$session_name.log" bash -c "source $HOME/.bashrc; sh $script --bind \"$bind_addr\" $log_output; echo '节点已退出，查看 screen 日志：$work_dir/screen_$session_name.log'; sleep 30"

  # 等待足够时间，确保 screen 会话初始化
  sleep 5

  # 检查 screen 会话是否运行
  if screen -ls | grep -q "$session_name"; then
    echo -e "${GREEN}[+] 节点已在 screen 会话 '$session_name' 中运行，可使用 'screen -r $session_name' 查看${RESET}"
    echo -e "${GREEN}[+] 所有步骤已成功完成！${RESET}"
    echo -e "工作目录：$work_dir"
    [ -n "$public_key" ] && echo -e "MINING_PUBKEY：$public_key"
    echo -e "Leader 端口：$LEADER_PORT"
    echo -e "Follower 端口：$FOLLOWER_PORT"
    echo -e "绑定地址：$bind_addr"
    if [ -f "wallet_keys.txt" ]; then
      echo -e "钱包密钥已生成，保存在 $work_dir/wallet_keys.txt，请妥善保存！"
    fi
    # 检查 miner.log 是否有内容（如果启用）
    if [[ "$log_to_file" =~ ^[Yy]$ ]] && [ -f "miner.log" ] && [ -s "miner.log" ]; then
      echo -e "${YELLOW}[!] miner.log 内容（最后 10 行）：${RESET}"
      tail -n 10 miner.log
    elif [[ "$log_to_file" =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}[!] miner.log 文件尚未生成或为空，请稍后检查或使用 'screen -r $session_name' 查看实时输出${RESET}"
    fi
    # 检查 screen 日志
    if [ -f "$work_dir/screen_$session_name.log" ] && [ -s "$work_dir/screen_$session_name.log" ]; then
      echo -e "${YELLOW}[!] screen_$session_name.log 内容（最后 10 行）：${RESET}"
      tail -n 10 "$work_dir/screen_$session_name.log"
    else
      echo -e "${YELLOW}[!] screen_$session_name.log 文件尚未生成或为空，可能是 screen 输出问题${RESET}"
    fi
  else
    echo -e "${RED}[-] 无法启动节点！请检查 $work_dir/screen_$session_name.log${RESET}"
    if [[ "$log_to_file" =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}[!] 最后 10 行 miner.log：${RESET}"
      tail -n 10 "$work_dir/miner.log" 2>/dev/null || echo -e "${YELLOW}[!] 未找到 miner.log${RESET}"
    fi
    echo -e "${YELLOW}[!] 最后 10 行 screen_$session_name.log：${RESET}"
    tail -n 10 "$work_dir/screen_$session_name.log" 2>/dev/null || echo -e "${YELLOW}[!] 未找到 screen_$session_name.log${RESET}"
  fi
  pause_and_return
}

# ========= 查看节点日志 =========
function view_logs() {
  LOG_FILE="$NCK_DIR/miner.log"
  if [ -f "$LOG_FILE" ]; then
    echo -e "${GREEN}[+] 正在显示日志文件：$LOG_FILE${RESET}"
    tail -f "$LOG_FILE"
  else
    echo -e "${RED}[-] 日志文件 $LOG_FILE 不存在，请确认是否已运行选项 7 启动节点并启用 miner.log 输出！${RESET}"
    echo -e "${YELLOW}[!] 您可以检查 screen 日志 $NCK_DIR/screen_miner.log 或 $NCK_DIR/screen_node.log${RESET}"
  fi
  pause_and_return
}

# ========= 主菜单 =========
function main_menu() {
  show_banner
  echo "请选择操作:"
  echo "  1) 安装系统依赖"
  echo "  2) 安装 Rust"
  echo "  3) 设置仓库"
  echo "  4) 编译项目和配置环境变量"
  echo "  5) 生成钱包"
  echo "  6) 设置挖矿公钥"
  echo "  7) 启动节点（Miner 或非 Miner）"
  echo "  8) 备份密钥"
  echo "  9) 查看节点日志"
  echo " 10) 查询余额"
  echo "  0) 退出"
  echo ""
  read -p "请输入编号: " choice
  case "$choice" in
    1) install_dependencies ;;
    2) install_rust ;;
    3) setup_repository ;;
    4) build_and_configure ;;
    5) generate_wallet ;;
    6) configure_mining_key ;;
    7) start_node ;;
    8) backup_keys ;;
    9) view_logs ;;
    10) check_balance ;;
    0) echo -e "${GREEN}已退出。${RESET}"; exit 0 ;;
    *) echo -e "${RED}[-] 无效选项！${RESET}"; pause_and_return ;;
  esac
}

# ========= 启动主程序 =========
main_menu
