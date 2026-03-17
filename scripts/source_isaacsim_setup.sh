# Detect script directory (works in both bash and zsh)
if [ -n "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
elif [ -n "${ZSH_VERSION}" ]; then
    SCRIPT_DIR=$( cd -- "$( dirname -- "${(%):-%x}" )" &> /dev/null && pwd )
fi

# Use CONDA_ENV_NAME if provided, otherwise default to "hssim"
# CONDA_ENV_NAME=${CONDA_ENV_NAME:-hssim}
CONDA_ENV_NAME=hssim

echo "conda environment name is set to: $CONDA_ENV_NAME"

source ${SCRIPT_DIR}/source_common.sh
source ${CONDA_ROOT}/bin/activate $CONDA_ENV_NAME
export OMNI_KIT_ACCEPT_EULA=1

# Validate environment is properly activated
if python -c "import isaacsim" 2>/dev/null; then
    echo "IsaacSim environment activated successfully"
    echo "IsaacSim version: $(python -c 'import isaacsim; import importlib.metadata as md; print(getattr(isaacsim, "__version__", md.version("isaacsim") if "isaacsim" in md.packages_distributions() else "unknown (metadata unavailable)"))')"
    echo "IsaacLab version: $(python -c 'import isaaclab; print(isaaclab.__version__)')"
    echo "PyTorch version: $(python -c 'import torch; print(torch.__version__)')"

    # Print IsaacLab commit if installed from the local clone.
    # if [ -d "${WORKSPACE_DIR}/IsaacLab/.git" ]; then
    #     ISAACLAB_COMMIT=$(git -C ${WORKSPACE_DIR}/IsaacLab rev-parse --short HEAD 2>/dev/null || echo "unknown")
    #     echo "IsaacLab commit: ${ISAACLAB_COMMIT}"
    # fi
else
    echo "Warning: IsaacSim environment activation may have issues"
fi
