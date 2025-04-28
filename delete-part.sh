#!/bin/bash

# 检查是否以root用户运行
if [ "$(id -u)" -ne 0 ]; then
    echo "请使用 root 用户运行此脚本！"
    exit 1
fi

# 检查 /home 是否挂载
if mount | grep -q "/home"; then
    echo "卸载 /home..."
    umount /home || { echo "卸载失败，请检查是否有进程占用！"; exit 1; }
fi

# 删除 /home 分区（nvme0n1p3）
echo "删除 /home 分区（nvme0n1p3）..."
fdisk /dev/nvme0n1 <<EOF
d
3
w
EOF

# 删除并重建 / 分区（nvme0n1p2），扩展空间
echo "扩展 / 分区（nvme0n1p2）..."
fdisk /dev/nvme0n1 <<EOF
d
2
n
p
2
2048

w
EOF

# 重新加载分区表
echo "重新加载分区表..."
partprobe /dev/nvme0n1

# 调整文件系统大小（假设是 ext4）
echo "调整文件系统大小..."
resize2fs /dev/nvme0n1p2

# 注释掉 /etc/fstab 中的 /home 挂载行
echo "更新 /etc/fstab..."
sed -i '/\/home/s/^/#/' /etc/fstab

# 显示结果
echo "操作完成！当前磁盘情况："
lsblk
df -h
