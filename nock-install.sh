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

# ========= 安装系统依赖 =========
function install_dependencies() {
  if ! command -v apt-get &> /dev/null; then
    echo -e "${RED}[-] 此脚本假设使用 Debian/Ubuntu 系统 (apt)。请手动安装依赖！${RESET}"
    pause_and_return
    return
  fi
  echo -e "[*] 更新系统并安装依赖..."
  apt-get update && apt-get upgrade -y && apt install -y sudo
  sudo apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip screen
  echo -e "${GREEN}[+] 依赖安装完成。${RESET}"
  pause_and_return
}

# ========= 安装 Rust =========
function install_rust() {
  if command -v rustc &> /dev/null; then
    echo -e "${YELLOW}[!] Rust 已安装，跳过安装。${RESET}"
    pause_and_return
    return
  fi
  echo -e "[*] 安装 Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env" || { echo -e "${RED}[-] 无法配置 Rust 环境变量！${RESET}"; pause_and_return; return; }
  rustup default stable
  echo -e "${GREEN}[+] Rust 安装完成。${RESET}"
  pause_and_return
}

# ========= 设置仓库 =========
function setup_repository() {
  echo -e "[*] 检查 nockchain 仓库..."
  if [ -d "$NCK_DIR" ]; then
    echo -e "${YELLOW}[?] 已存在 nockchain 目录，是否删除重新克隆？(y/n)${RESET}"
    read -r confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
      rm -rf "$NCK_DIR" "$HOME/.nockapp"
      git clone https://github.com/zorp-corp/nockchain "$NCK_DIR"
    else
      cd "$NCK_DIR" && git pull
    fi
  else
    git clone https://github.com/zorp-corp/nockchain "$NCK_DIR"
  fi
  if [ $? -ne 0 ]; then
    echo -e "${RED}[-] 克隆仓库失败，请检查网络或权限！${RESET}"
    pause_and_return
    return
  fi
  cd "$NCK_DIR" || { echo -e "${RED}[-] 无法进入 nockchain 目录！${RESET}"; pause_and_return; return; }
  if [ -f ".env" ]; then
    cp .env .env.bak
    echo -e "[*] .env 已备份为 .env.bak"
  fi
  if [ -f ".env_example" ]; then
    cp .env_example .env
    echo -e "${GREEN}[+] 环境文件 .env 已创建。${RESET}"
  else
    echo -e "${RED}[-] 未找到 .env_example 文件，请检查仓库！${RESET}"
  fi
  echo -e "${GREEN}[+] 仓库设置完成。${RESET}"
  pause_and_return
}

# ========= 编译项目和配置环境变量 =========
function build_and_configure() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain 目录不存在，请先运行选项 3 设置仓库！${RESET}"
    pause_and_return
    return
  fi
  cd "$NCK_DIR" || { echo -e "${RED}[-] 无法进入 nockchain 目录！${RESET}"; pause_and_return; return; }
  echo -e "[*] 编译核心组件..."
  make install-hoonc || { echo -e "${RED}[-] 执行 make install-hoonc 失败，请检查 Makefile 或依赖！${RESET}"; pause_and_return; return; }
  if command -v hoonc &> /dev/null; then
    echo -e "[*] hoonc 安装成功，可用命令：hoonc"
  else
    echo -e "${YELLOW}[!] 警告：hoonc 命令不可用，安装可能不完整。${RESET}"
  fi
  make build || { echo -e "${RED}[-] 执行 make build 失败，请检查 Makefile 或依赖！${RESET}"; pause_and_return; return; }
  make install-nockchain-wallet || { echo -e "${RED}[-] 执行 make install-nockchain-wallet 失败，请检查 Makefile 或依赖！${RESET}"; pause_and_return; return; }
  make install-nockchain || { echo -e "${RED}[-] 执行 make install-nockchain 失败，请检查 Makefile 或依赖！${RESET}"; pause_and_return; return; }
  echo -e "[*] 配置环境变量..."
  RC_FILE="$HOME/.bashrc"
  [[ "$SHELL" == *"zsh"* ]] && RC_FILE="$HOME/.zshrc"
  if ! grep -q "$NCK_DIR/target/release" "$RC_FILE"; then
    echo "export PATH=\"\$PATH:$NCK_DIR/target/release\"" >> "$RC_FILE"
    source "$RC_FILE" || echo -e "${YELLOW}[!] 无法立即应用环境变量，请手动 source $RC_FILE 或重新打开终端。${RESET}"
  else
    source "$RC_FILE" || echo -e "${YELLOW}[!] 无法立即应用环境变量，请手动 source $RC_FILE 或重新打开终端。${RESET}"
  fi
  echo -e "${GREEN}[+] 编译和环境变量配置完成。${RESET}"
  pause_and_return
}

# ========= 生成钱包 =========
function generate_wallet() {
  if [ ! -d "$NCK_DIR" ] || [ ! -f "$NCK_DIR/target/release/nockchain-wallet" ]; then
    echo -e "${RED}[-] 未找到钱包命令或 nockchain 目录，请先运行选项 3 和 4！${RESET}"
    pause_and_return
    return
  fi
  cd "$NCK_DIR" || { echo -e "${RED}[-] 无法进入 nockchain 目录！${RESET}"; pause_and_return; return; }
  echo -e "[*] 生成钱包密钥对..."
  read -p "[?] 是否创建钱包？[Y/n]: " create_wallet
  create_wallet=${create_wallet:-y}
  if [[ ! "$create_wallet" =~ ^[Yy]$ ]]; then
    echo -e "[*] 已跳过钱包创建。"
    pause_and_return
    return
  fi
  if ! command -v nockchain-wallet &> /dev/null; then
    echo -e "${RED}[-] nockchain-wallet 命令不可用，请检查 target/release 目录或构建过程！${RESET}"
    pause_and_return
    return
  fi
  nockchain-wallet keygen > wallet_keys.txt 2>&1 || { echo -e "${RED}[-] nockchain-wallet keygen 执行失败！${RESET}"; pause_and_return; return; }
  echo -e "${GREEN}[+] 钱包密钥已保存到 $NCK_DIR/wallet_keys.txt，请妥善保管！${RESET}"
  PUBLIC_KEY=$(grep -i "public key" wallet_keys.txt | awk '{print $NF}' | tail -1)
  if [ -n "$PUBLIC_KEY" ]; then
    echo -e "${YELLOW}公钥:${RESET}\n$PUBLIC_KEY"
    echo -e "${YELLOW}[!] 请使用选项 6 设置挖矿公钥或手动将以下公钥添加到 $NCK_DIR/.env 文件中：${RESET}"
    echo -e "MINING_PUBKEY=$PUBLIC_KEY"
  else
    echo -e "${RED}[-] 无法提取公钥，请检查 wallet_keys.txt！${RESET}"
  fi
  echo -e "${GREEN}[+] 钱包生成完成。${RESET}"
  pause_and_return
}

# ========= 设置挖矿公钥 =========
function configure_mining_key() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain 目录不存在，请先运行选项 3！${RESET}"
    pause_and_return
    return
  fi
  cd "$NCK_DIR" || { echo -e "${RED}[-] 无法进入 nockchain 目录！${RESET}"; pause_and_return; return; }
  echo -e "[*] 设置挖矿公钥（MINING_PUBKEY）..."
  read -p "[?] 请输入您的 MINING_PUBKEY（可从选项 5 获取）： " public_key
  if [ -z "$public_key" ]; then
    echo -e "${RED}[-] 未提供 MINING_PUBKEY，请输入有效的公钥！${RESET}"
    pause_and_return
    return
  fi
  if [ ! -f ".env" ]; then
    echo -e "${RED}[-] .env 文件不存在，请先运行选项 3 设置仓库！${RESET}"
    pause_and_return
    return
  fi
  if ! grep -q "^MINING_PUBKEY=" .env; then
    echo "MINING_PUBKEY=$public_key" >> .env
  else
    sed -i "s|^MINING_PUBKEY=.*|MINING_PUBKEY=$public_key|" .env || {
      echo -e "${RED}[-] 无法更新 .env 文件中的 MINING_PUBKEY！${RESET}"
      pause_and_return
      return
    }
  fi
  if grep -q "^MINING_PUBKEY=$public_key$" .env; then
    echo -e "${GREEN}[+] .env 文件中的 MINING_PUBKEY 更新成功！${RESET}"
  else
    echo -e "${RED}[-] .env 文件更新失败，请检查文件内容！${RESET}"
  fi
  echo -e "${GREEN}[+] 挖矿公钥设置完成。${RESET}"
  pause_and_return
}

# ========= 启动 Miner 节点 =========
function start_miner_node() {
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
    echo -e "${YELLOW}[!] 请确保 \$PATH 包含 $NCK_DIR/target/release，可运行 'source ~/.bashrc' 或重新打开终端${RESET}"
    pause_and_return
    return
  fi

  # 验证 screen 和 tee 命令是否可用
  echo -e "[*] 正在验证 screen 和 tee 命令..."
  if ! command -v screen &> /dev/null; then
    echo -e "${RED}[-] screen 命令不可用，请确保已安装 screen（运行选项 1 或手动安装）！${RESET}"
    pause_and_return
    return
  fi
  if ! command -v tee &> /dev/null; then
    echo -e "${RED}[-] tee 命令不可用，请确保已安装 tee（运行选项 1 或手动安装）！${RESET}"
    pause_and_return
    return
  fi

  # 从 .env 文件中读取公钥
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

  # 默认端口
  LEADER_PORT=3005
  FOLLOWER_PORT=3006
  PORTS_TO_CHECK=("$LEADER_PORT" "$FOLLOWER_PORT")
  PORTS_OCCUPIED=false
  declare -A PID_PORT_MAP

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
        if commandocator lsof &> /dev/null && lsof -i :$PORT -t >/dev/null 2>&1; then
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
      echo -e "${RED}[-] 用户取消杀死进程，无法启动 Miner 节点！${RESET}"
      pause_and_return
      return
    fi
  else
    echo -e "${GREEN}[+] 端口 $LEADER_PORT 和 $FOLLOWER_PORT 未被占用。${RESET}"
  fi

  # 清理现有的 miner screen 会话
  echo -e "[*] 正在清理现有的 miner screen 会话..."
  screen -ls | grep -q "miner" && screen -X -S miner quit

  # 启动 Miner 节点，使用公钥和 peer 参数
  echo -e "[*] 正在启动 Miner 节点..."
  NOCKCHAIN_CMD="RUST_LOG=trace ./target/release/nockchain --mining-pubkey \"$public_key\" --mine --peer /ip4/95.216.102.60/udp/3006/quic-v1 --peer /ip4/65.108.123.225/udp/3006/quic-v1 --peer /ip4/65.109.156.108/udp/3006/quic-v1 --peer /ip4/65.21.67.175/udp/3006/quic-v1 --peer /ip4/65.109.156.172/udp/3006/quic-v1 --peer /ip4/34.174.22.166/udp/3006/quic-v1 --peer /ip4/34.95.155.151/udp/30000/quic-v1 --peer /ip4/34.18.98.38/udp/30000/quic-v1"

  # 修改 screen 命令，确保输出可见
  echo -e "${GREEN}[+] 启动 nockchain 节点在 screen 会话 'miner' 中，日志同时输出到 $NCK_DIR/miner.log${RESET}"
  echo -e "${YELLOW}[!] 使用 'screen -r miner' 查看节点实时输出，Ctrl+A 然后 D 脱离 screen（节点继续运行）${RESET}"
  # 使用 -L 记录 screen 日志，并确保命令在 bash 中运行
  screen -dmS miner -L -Logfile "$NCK_DIR/screen_miner.log" bash -c "source $HOME/.bashrc; $NOCKCHAIN_CMD 2>&1 | tee -a miner.log; echo 'nockchain 已退出，查看日志：$NCK_DIR/miner.log'; sleep 30"

  # 等待更长时间，确保 screen 会话初始化
  sleep 5

  # 检查 screen 会话是否运行
  if screen -ls | grep -q "miner"; then
    echo -e "${GREEN}[+] Miner 节点已在 screen 会话 'miner' 中运行，可使用 'screen -r miner' 查看${RESET}"
    echo -e "${GREEN}[+] 所有步骤已成功完成！${RESET}"
    echo -e "当前目录：$(pwd)"
    echo -e "MINING_PUBKEY 已设置为：$public_key"
    echo -e "Leader 端口：$LEADER_PORT"
    echo -e "Follower 端口：$FOLLOWER_PORT"
    if [ -f "wallet_keys.txt" ]; then
      echo -e "钱包密钥已生成，保存在 $NCK_DIR/wallet_keys.txt，请妥善保存！"
    fi
    # 检查 miner.log 是否有内容
    if [ -f "miner.log" ] && [ -s "miner.log" ]; then
      echo -e "${YELLOW}[!] miner.log 内容：${RESET}"
      tail -n 10 miner.log
    else
      echo -e "${YELLOW}[!] miner.log 文件尚未生成或为空，请稍后检查或使用 'screen -r miner' 查看实时输出${RESET}"
    fi
    # 检查 screen 日志
    if [ -f "$NCK_DIR/screen_miner.log" ] && [ -s "$NCK_DIR/screen_miner.log" ]; then
      echo -e "${YELLOW}[!] screen_miner.log 内容（最后 10 行）：${RESET}"
      tail -n 10 "$NCK_DIR/screen_miner.log"
    else
      echo -e "${YELLOW}[!] screen_miner.log 文件尚未生成或为空，可能是 screen 输出问题${RESET}"
    fi
  else
    echo -e "${RED}[-] 无法启动 Miner 节点！请检查 $NCK_DIR/miner.log 和 $NCK_DIR/screen_miner.log${RESET}"
    echo -e "${YELLOW}[!] 最后 10 行 miner.log：${RESET}"
    tail -n 10 "$NCK_DIR/miner.log" 2>/dev/null || echo -e "${YELLOW}[!] 未找到 miner.log${RESET}"
    echo -e "${YELLOW}[!] 最后 10 行 screen_miner.log：${RESET}"
    tail -n 10 "$NCK_DIR/screen_miner.log" 2>/dev/null || echo -e "${YELLOW}[!] 未找到 screen_miner.log${RESET}"
  fi
  pause_and_return
}

# ========= 备份密钥 =========
function backup_keys() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain 目录不存在，请先运行选项 3！${RESET}"
    pause_and_return
    return
  fi
  if ! command -v nockchain-wallet &> /dev/null; then
    echo -e "${RED}[-] nockchain-wallet 命令不可用，请先运行选项 4！${RESET}"
    pause_and_return
    return
  fi
  cd "$NCK_DIR" || { echo -e "${RED}[-] 无法进入 nockchain 目录！${RESET}"; pause_and_return; return; }
  echo -e "[*] 备份密钥..."
  nockchain-wallet export-keys > nockchain_keys_backup.txt 2>&1
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}[+] 密钥备份成功！已保存到 $NCK_DIR/nockchain_keys_backup.txt${RESET}"
    echo -e "${YELLOW}[!] 请妥善保管该文件，切勿泄露！${RESET}"
  else
    echo -e "${RED}[-] 密钥备份失败，请检查 nockchain-wallet export-keys 命令输出！${RESET}"
    echo -e "${YELLOW}[!] 详细信息见 $NCK_DIR/nockchain_keys_backup.txt${RESET}"
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
    echo -e "${RED}[-] 日志文件 $LOG_FILE 不存在，请确认是否已运行选项 7 启动 Miner 节点！${RESET}"
  fi
  pause_and_return
}

# ========= 查询余额 =========
function check_balance() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain 目录不存在，请先运行选项 3！${RESET}"
    pause_and_return
    return
  fi
  if ! command -v nockchain-wallet &> /dev/null; then
    echo -e "${RED}[-] nockchain-wallet 命令不可用，请先运行选项 4！${RESET}"
    pause_and_return
    return
  fi
  cd "$NCK_DIR" || { echo -e "${RED}[-] 无法进入 nockchain 目录！${RESET}"; pause_and_return; return; }

  # 检查 socket 文件
  SOCKET_PATH="/opt/nockchain/.socket/nockchain_npc.sock"
  if [ ! -S "$SOCKET_PATH" ]; then
    echo -e "${RED}[-] socket 文件 $SOCKET_PATH 不存在，请确保 nockchain 节点正在运行（可尝试选项 7）！${RESET}"
    pause_and_return
    return
  fi

  # 执行余额查询
  echo -e "[*] 正在查询余额..."
  nockchain-wallet --nockchain-socket "$SOCKET_PATH" update-balance > balance_output.txt 2>&1
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}[+] 余额查询成功！以下是查询结果：${RESET}"
    echo -e "----------------------------------------"
    cat balance_output.txt
    echo -e "----------------------------------------"
  else
    echo -e "${RED}[-] 余额查询失败，请检查 nockchain-wallet 命令或节点状态！${RESET}"
    echo -e "${YELLOW}[!] 详细信息见 $NCK_DIR/balance_output.txt${RESET}"
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
  echo "  7) 启动 Miner 节点"
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
    7) start_miner_node ;;
    8) backup_keys ;;
    9) view_logs ;;
    10) check_balance ;;
    0) echo -e "${GREEN}已退出。${RESET}"; exit 0 ;;
    *) echo -e "${RED}[-] 无效选项！${RESET}"; pause_and_return ;;
  esac
}

# ========= 启动主程序 =========
main_menu
