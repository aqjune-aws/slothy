#!/usr/bin/env sh

set -e

SLOTHY_DIR=.
CLEAN_DIR=./mul/clean
OPT_DIR=./mul/opt

LOG_DIR=./logs
mkdir -p $LOG_DIR

REDIRECT_OUTPUT="--log --logdir=${LOG_DIR}"

${SLOTHY_DIR}/slothy-cli Arm_AArch64 Arm_Cortex_A55 \
    ${CLEAN_DIR}/bignum_mul_8_16_neon.objdump.nostack.s \
    -o ${OPT_DIR}/test_nosymvars.s \
    -c reserved_regs="[x18]" -c outputs="[x0]" \
    -c /visualize_reordering \
    $REDIRECT_OUTPUT
#    -c outputs="[x10,x11]"
#    -c constraints.allow_reordering=False                                    \
#    -c constraints.functional_only=True                                      \
#    -c inputs_are_outputs -c outputs="[x10;x11]" -c reserved_regs="[x18]"         \
#    -s mainloop -e end_label                                                 \
#    -c /visualize_reordering -c inherit_macro_comments                       \

