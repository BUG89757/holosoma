#!/usr/bin/env bash

# More detailed test for the convert_data_format_mj.py shutdown path.
# This runs conversion on a short frame range, verifies that the output file
# is readable and contains expected keys/shapes, then removes the temporary
# output file after verification.

set -e

SOURCE="${BASH_SOURCE[0]:-${(%):-%x}}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Sourcing retargeting setup..."
source "$PROJECT_ROOT/scripts/source_retargeting_setup.sh"

RETARGET_DIR="$PROJECT_ROOT/src/holosoma_retargeting/holosoma_retargeting"
cd "$RETARGET_DIR"

INPUT_FILE="${1:-./demo_results/g1/robot_only/omomo/sub3_largebox_003.npz}"
OUTPUT_FILE="${2:-/tmp/holosoma_conversion_shutdown_test.npz}"
LINE_START="${3:-0}"
LINE_END="${4:-100}"

echo "Testing conversion shutdown path..."
echo "Input: $INPUT_FILE"
echo "Output: $OUTPUT_FILE"
echo "Frame range: $LINE_START to $LINE_END"
echo "Working directory: $RETARGET_DIR"

set +e
python data_conversion/convert_data_format_mj.py \
  --input_file "$INPUT_FILE" \
  --output_fps 50 \
  --output_name "$OUTPUT_FILE" \
  --data_format smplh \
  --object_name ground \
  --line-range "$LINE_START" "$LINE_END" \
  --once
EXIT_CODE=$?
set -e

echo "Process exit code: $EXIT_CODE"
if [ -f "$OUTPUT_FILE" ]; then
  echo "Output file was written:"
  ls -lh "$OUTPUT_FILE"

  echo "Verifying output file contents..."
  python - <<PY
from pathlib import Path
import numpy as np

output_file = Path("$OUTPUT_FILE")
required_keys = [
    "fps",
    "joint_pos",
    "joint_vel",
    "body_pos_w",
    "body_quat_w",
    "body_lin_vel_w",
    "body_ang_vel_w",
    "joint_names",
    "body_names",
]

print(f"Readable file: {output_file}")
with np.load(output_file, allow_pickle=True) as data:
    keys = sorted(data.files)
    print("Available keys:", keys)

    missing = [k for k in required_keys if k not in data]
    if missing:
        raise SystemExit(f"Missing required keys: {missing}")

    print("fps:", data["fps"].tolist())
    print("joint_pos shape:", data["joint_pos"].shape)
    print("joint_vel shape:", data["joint_vel"].shape)
    print("body_pos_w shape:", data["body_pos_w"].shape)
    print("body_quat_w shape:", data["body_quat_w"].shape)
    print("body_lin_vel_w shape:", data["body_lin_vel_w"].shape)
    print("body_ang_vel_w shape:", data["body_ang_vel_w"].shape)
    print("num joint names:", len(data["joint_names"]))
    print("num body names:", len(data["body_names"]))

    num_frames = data["joint_pos"].shape[0]
    if num_frames == 0:
        raise SystemExit("joint_pos has zero frames")

    if data["joint_pos"].shape[0] != data["joint_vel"].shape[0]:
        raise SystemExit("joint_pos and joint_vel frame counts do not match")

    if data["body_pos_w"].shape[0] != num_frames:
        raise SystemExit("body_pos_w frame count does not match joint_pos")

    print("Verification result: output file is readable and structurally valid.")
PY
else
  echo "Output file was not written."
fi

if [ -f "$OUTPUT_FILE" ]; then
  echo "Removing temporary test output..."
  rm -f "$OUTPUT_FILE"
  if [ -f "$OUTPUT_FILE" ]; then
    echo "Warning: failed to remove temporary test output."
  else
    echo "Temporary test output removed."
  fi
fi

exit "$EXIT_CODE"
