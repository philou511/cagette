/// <reference types="react" />
export interface StepperProps {
    activeStep: 0 | 1 | 2;
    disableAlert?: boolean;
}
declare const Stepper: ({ activeStep, disableAlert }: StepperProps) => JSX.Element;
export default Stepper;
