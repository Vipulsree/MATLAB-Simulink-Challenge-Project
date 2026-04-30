/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: ABS_Controller_core.c
 *
 * Code generated for Simulink model 'ABS_Controller_core'.
 *
 * Model version                  : 11.15
 * Simulink Coder version         : 25.2 (R2025b) 28-Jul-2025
 * C/C++ source code generated on : Tue Apr 28 21:21:51 2026
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: ARM Compatible->ARM Cortex
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "ABS_Controller_core.h"
#include "rtwtypes.h"
#include "ABS_Controller_core_private.h"
#include "look1_binlx.h"

/* Output and update for referenced model: 'ABS_Controller_core' */
void ABS_Controller_core(const real_T *rtu_SlpErr, const real_T
  *rtu_RoadCondition, real_T *rty_controllerout, DW_ABS_Controller_core_f_T
  *localDW)
{
  real_T rtb_NProdOut;
  real_T u0;

  /* Product: '<S39>/NProd Out' incorporates:
   *  DiscreteIntegrator: '<S31>/Filter'
   *  Lookup_n-D: '<Root>/1-D Lookup Table1'
   *  Lookup_n-D: '<Root>/1-D Lookup Table3'
   *  Product: '<S29>/DProd Out'
   *  Sum: '<S31>/SumD'
   */
  rtb_NProdOut = ((*rtu_SlpErr * look1_binlx(*rtu_RoadCondition,
    ABS_Controller_core_ConstP.pooled1,
    ABS_Controller_core_ConstP.uDLookupTable1_tableData, 2U)) -
                  localDW->Filter_DSTATE) * look1_binlx(*rtu_RoadCondition,
    ABS_Controller_core_ConstP.pooled1,
    ABS_Controller_core_ConstP.uDLookupTable3_tableData, 2U);

  /* Sum: '<S45>/Sum' incorporates:
   *  DiscreteIntegrator: '<S36>/Integrator'
   *  Lookup_n-D: '<Root>/1-D Lookup Table2'
   *  Product: '<S41>/PProd Out'
   */
  u0 = (*rtu_SlpErr * look1_binlx(*rtu_RoadCondition,
         ABS_Controller_core_ConstP.pooled1,
         ABS_Controller_core_ConstP.uDLookupTable2_tableData, 2U)) +
    localDW->Integrator_DSTATE + rtb_NProdOut;

  /* Saturate: '<S43>/Saturation' */
  if (u0 > 1.0) {
    *rty_controllerout = 1.0;
  } else if (u0 < -1.0) {
    *rty_controllerout = -1.0;
  } else {
    *rty_controllerout = u0;
  }

  /* End of Saturate: '<S43>/Saturation' */

  /* Update for DiscreteIntegrator: '<S31>/Filter' */
  localDW->Filter_DSTATE += 0.01 * rtb_NProdOut;

  /* Update for DiscreteIntegrator: '<S36>/Integrator' incorporates:
   *  Lookup_n-D: '<Root>/1-D Lookup Table'
   *  Product: '<S33>/IProd Out'
   */
  localDW->Integrator_DSTATE += (*rtu_SlpErr * look1_binlx(*rtu_RoadCondition,
    ABS_Controller_core_ConstP.pooled1,
    ABS_Controller_core_ConstP.uDLookupTable_tableData, 2U)) * 0.01;
}

/* Model initialize function */
void ABS_Controller_core_initialize(const char_T **rt_errorStatus,
  RT_MODEL_ABS_Controller_core_T *const ABS_Controller_core_M)
{
  /* Registration code */

  /* initialize error status */
  rtmSetErrorStatusPointer(ABS_Controller_core_M, rt_errorStatus);
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
