#!/bin/bash  
  
# 检查是否存在 .git/hooks/prepare-commit-msg.sample  
if [ -f ".git/hooks/prepare-commit-msg.sample" ]; then  
    # 复制并设置可执行权限  
    cp .git/hooks/prepare-commit-msg.sample .git/hooks/prepare-commit-msg  
    chmod +x .git/hooks/prepare-commit-msg  
    echo "prepare-commit-msg hook installed and set to executable."  
else  
    echo "prepare-commit-msg.sample hook not found."  
fi