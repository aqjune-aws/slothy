#!/usr/bin/env sh

set -e

SLOTHY_DIR=.
CLEAN_DIR=./mul/clean
OPT_DIR=./mul/opt

LOG_DIR=./logs
mkdir -p $LOG_DIR

REDIRECT_OUTPUT="--log --logdir=${LOG_DIR}"

#${SLOTHY_DIR}/slothy-cli Arm_AArch64 Arm_Cortex_A55 \
#    ${CLEAN_DIR}/bignum_mul_8_16_neon.objdump.nostack.s \
#    -o ${OPT_DIR}/test_nosymvars.s \
#    -c reserved_regs="[x18]" -c outputs=[hint_buffer32,hint_buffer48,hint_buffer64,hint_buffer80,hint_buffer96,hint_buffer112] \
#    -c /visualize_reordering \
#    $REDIRECT_OUTPUT

OUTPUTS="[hint_buffer32,hint_buffer48,hint_buffer64,hint_buffer80,hint_buffer96,hint_buffer112]"

echo "** Step 0: Resolve symbolic registers"
${SLOTHY_DIR}/slothy-cli Arm_AArch64 Arm_Cortex_A55                          \
       ${CLEAN_DIR}/bignum_mul_8_16_neon.objdump.nostack.s                             \
    -o ${OPT_DIR}/bignum_mul_8_16_neon.objdump.nostack_nosymvars.s                     \
    -c outputs=$OUTPUTS -c reserved_regs="[x18]"         \
    -c constraints.allow_reordering=False                                    \
    -c constraints.functional_only=True                                      \
    -c /visualize_reordering \
    $REDIRECT_OUTPUT

echo "** Step 1: Preprocessing"
${SLOTHY_DIR}/slothy-cli Arm_AArch64 Arm_Cortex_A55                          \
       ${OPT_DIR}/bignum_mul_8_16_neon.objdump.nostack_nosymvars.s                     \
    -o ${OPT_DIR}/bignum_mul_8_16_neon.objdump.nostack_unfold_process0.s               \
    -c outputs=$OUTPUTS -c reserved_regs="[x18]"         \
    -c split_heuristic -c split_heuristic_repeat=0                           \
    -c split_heuristic_preprocess_naive_interleaving                         \
    -c /visualize_reordering \
    $REDIRECT_OUTPUT

echo "** Steps 2-6: Stepwise optimization, ignoring latencies"
# The goal here is to get a good amount of interleaving
# The best order of subregions is still TBD, but presently we 'comb' all stalls
# towards the middle of the code and repeat the process. The idea/hope is that
# by doing this multiple times, the stalls will eventually be absorbed.

echo "*** Step 2"
i=0
    ${SLOTHY_DIR}/slothy-cli Arm_AArch64 Arm_Cortex_A55                      \
       ${OPT_DIR}/bignum_mul_8_16_neon.objdump.nostack_unfold_process${i}.s            \
    -o ${OPT_DIR}/bignum_mul_8_16_neon.objdump.nostack_unfold_process$((${i}+1)).s     \
    -c outputs=$OUTPUTS -c reserved_regs="[x18]"         \
    -c variable_size                                                         \
    -c max_solutions=512                                                     \
    -c timeout=300                                                           \
    -c constraints.stalls_first_attempt=32                                   \
    -c split_heuristic                                                       \
    -c split_heuristic_region="[0,1]"                                        \
    -c objective_precision=0.1                                               \
    -c split_heuristic_stepsize=0.1                                          \
    -c split_heuristic_factor=6                                              \
    -c constraints.model_latencies=False                                     \
    -c /visualize_reordering \
    $REDIRECT_OUTPUT

echo "*** Step 3"
i=1
    ${SLOTHY_DIR}/slothy-cli Arm_AArch64 Arm_Cortex_A55                      \
       ${OPT_DIR}/bignum_mul_8_16_neon.objdump.nostack_unfold_process${i}.s            \
    -o ${OPT_DIR}/bignum_mul_8_16_neon.objdump.nostack_unfold_process$((${i}+1)).s     \
    -c outputs=$OUTPUTS -c reserved_regs="[x18]"         \
    -c variable_size                                                         \
    -c max_solutions=512                                                     \
    -c timeout=180                                                           \
    -c constraints.stalls_first_attempt=32                                   \
    -c split_heuristic                                                       \
    -c split_heuristic_region="[0,0.6]"                                      \
    -c objective_precision=0.1                                               \
    -c constraints.move_stalls_to_bottom                                     \
    -c split_heuristic_stepsize=0.1                                          \
    -c split_heuristic_factor=4                                              \
    -c constraints.model_latencies=False                                     \
    -c /visualize_reordering \
    $REDIRECT_OUTPUT

echo "*** Step 4"
i=2
    ${SLOTHY_DIR}/slothy-cli Arm_AArch64 Arm_Cortex_A55                      \
       ${OPT_DIR}/bignum_mul_8_16_neon.objdump.nostack_unfold_process${i}.s            \
    -o ${OPT_DIR}/bignum_mul_8_16_neon.objdump.nostack_unfold_process$((${i}+1)).s     \
    -c outputs=$OUTPUTS -c reserved_regs="[x18]"         \
    -c variable_size                                                         \
    -c max_solutions=512                                                     \
    -c timeout=240                                                           \
    -c constraints.stalls_first_attempt=32                                   \
    -c split_heuristic                                                       \
    -c split_heuristic_region="[0.3,1]"                                      \
    -c objective_precision=0.1                                               \
    -c constraints.move_stalls_to_top                                        \
    -c split_heuristic_stepsize=0.08                                         \
    -c split_heuristic_factor=6                                              \
    -c split_heuristic_repeat=3                                              \
    -c constraints.model_latencies=False                                     \
    -c /visualize_reordering \
    $REDIRECT_OUTPUT

echo "*** Step 5"
i=3
    ${SLOTHY_DIR}/slothy-cli Arm_AArch64 Arm_Cortex_A55                      \
       ${OPT_DIR}/bignum_mul_8_16_neon.objdump.nostack_unfold_process${i}.s            \
    -o ${OPT_DIR}/bignum_mul_8_16_neon.objdump.nostack_unfold_process$((${i}+1)).s     \
    -c outputs=$OUTPUTS -c reserved_regs="[x18]"         \
    -c variable_size                                                         \
    -c max_solutions=512                                                     \
    -c timeout=240                                                           \
    -c constraints.stalls_first_attempt=32                                   \
    -c split_heuristic                                                       \
    -c split_heuristic_region="[0.3,1]"                                      \
    -c objective_precision=0.1                                               \
    -c constraints.move_stalls_to_top                                        \
    -c split_heuristic_stepsize=0.05                                         \
    -c split_heuristic_factor=5                                              \
    -c split_heuristic_repeat=3                                              \
    -c split_heuristic_abort_cycle_at=8                                      \
    -c constraints.model_latencies=False                                     \
    -c /visualize_reordering \
    $REDIRECT_OUTPUT

echo "*** Step 6"
i=4
    ${SLOTHY_DIR}/slothy-cli Arm_AArch64 Arm_Cortex_A55                      \
       ${OPT_DIR}/bignum_mul_8_16_neon.objdump.nostack_unfold_process${i}.s            \
    -o ${OPT_DIR}/bignum_mul_8_16_neon.objdump.nostack_unfold_process$((${i}+1)).s     \
    -c outputs=$OUTPUTS -c reserved_regs="[x18]"         \
    -c variable_size                                                         \
    -c max_solutions=512                                                     \
    -c timeout=180                                                           \
    -c constraints.stalls_first_attempt=32                                   \
    -c split_heuristic                                                       \
    -c split_heuristic_region="[0.2,1]"                                      \
    -c objective_precision=0.1                                               \
    -c constraints.move_stalls_to_top                                        \
    -c split_heuristic_stepsize=0.05                                         \
    -c split_heuristic_factor=5                                              \
    -c split_heuristic_repeat=3                                              \
    -c split_heuristic_abort_cycle_at=5                                      \
    -c constraints.model_latencies=False                                     \
    -c /visualize_reordering \
    $REDIRECT_OUTPUT

# Finally, also consider latencies

echo "** Step 7-9: Consider latencies"
echo "*** Step 7"
i=5
   ${SLOTHY_DIR}/slothy-cli Arm_AArch64 Arm_Cortex_A55                       \
       ${OPT_DIR}/bignum_mul_8_16_neon.objdump.nostack_unfold_process${i}.s            \
    -o ${OPT_DIR}/bignum_mul_8_16_neon.objdump.nostack_unfold_process$((${i}+1)).s     \
    -c outputs=$OUTPUTS -c reserved_regs="[x18]"         \
    -c variable_size                                                         \
    -c max_solutions=512                                                     \
    -c timeout=300                                                           \
    -c constraints.stalls_first_attempt=32                                   \
    -c split_heuristic                                                       \
    -c split_heuristic_region="[0,1]"                                        \
    -c objective_precision=0.1                                               \
    -c split_heuristic_stepsize=0.05                                         \
    -c split_heuristic_optimize_seam=10                                      \
    -c split_heuristic_factor=8                                              \
    -c split_heuristic_repeat=10                                             \
    -c /visualize_reordering \
    $REDIRECT_OUTPUT

echo "*** Step 8"
i=6
  ${SLOTHY_DIR}/slothy-cli Arm_AArch64 Arm_Cortex_A55                       \
      ${OPT_DIR}/bignum_mul_8_16_neon.objdump.nostack_unfold_process${i}.s         \
   -o ${OPT_DIR}/bignum_mul_8_16_neon.objdump.nostack_unfold_process$((${i}+1)).s  \
    -c outputs=$OUTPUTS -c reserved_regs="[x18]"         \
   -c variable_size                                                         \
   -c max_solutions=512                                                     \
   -c timeout=300                                                           \
   -c constraints.stalls_first_attempt=32                                   \
   -c split_heuristic                                                       \
   -c split_heuristic_region="[0,1]"                                        \
   -c objective_precision=0.1                                               \
   -c split_heuristic_stepsize=0.05                                         \
   -c split_heuristic_optimize_seam=10                                      \
   -c split_heuristic_factor=8                                              \
   -c split_heuristic_repeat=3                                              \
   -c /visualize_reordering \
    $REDIRECT_OUTPUT

echo "*** Step 9"
i=7
  ${SLOTHY_DIR}/slothy-cli Arm_AArch64 Arm_Cortex_A55                       \
      ${OPT_DIR}/bignum_mul_8_16_neon.objdump.nostack_unfold_process${i}.s         \
   -o ${OPT_DIR}/bignum_mul_8_16_neon.objdump.nostack_opt.s                           \
    -c outputs=$OUTPUTS -c reserved_regs="[x18]"         \
   -c variable_size                                                         \
   -c max_solutions=512                                                     \
   -c timeout=300                                                           \
   -c constraints.stalls_first_attempt=32                                   \
   -c split_heuristic                                                       \
   -c split_heuristic_region="[0,1]"                                        \
   -c objective_precision=0.1                                               \
   -c split_heuristic_stepsize=0.05                                         \
   -c split_heuristic_optimize_seam=10                                      \
   -c split_heuristic_factor=8                                              \
   -c split_heuristic_repeat=3                                              \
   -c constraints.move_stalls_to_top                                        \
   -c /visualize_reordering \
    $REDIRECT_OUTPUT

cd "${0%/*}"

