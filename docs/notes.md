# System setup notes and observations

## OctoPrint-PSUControl

Since the **udev** dynamic allocation of `/dev/ttyANYCUBIC` causes a restart of
the docker s6 services, the default behaviour of PSUControl plugin is to reset
the state of the printer which would turns it back off.

You also can't use the relay output as an input and can't configure its initial
output to low or it will switch the printer off immediately after you switch it
on. Trying to reconfigure a single GPIO to read an input or configure an output
with no initial state, also results in driving the relay low and removing power
at the wrong time.

The recommended setting is to use a bridged jumper between GPIO 5 and 6, where
GPIO 5 will be the `switch` configured as an output and
GPIO 6 will be the `sense` input, pulled down and tracking the switch.

To work with a simple relay control that preserves the printer power state,
the `OctoPrint-PSUControl` repo needed to be forked and modified to:

* Change the order of **`configure_gpio`** to setup `sense` before `switch`
* Use the `sense` pin to determine the power supply state of the printer after
an OctoPrint restart i.e. don't turn it off it it's already on
* Use the initial state from `sense` to set the initial output of `switch`
* Ensure in **`turn_psu_off`** that the printer is disconnected before removing
power, to avoid crashing OctoPrint and getting into an ugly state

The forked repo can be found [here](https://github.com/gbrucepayne/OctoPrint-PSUControl)
in the **dynamic-serial** branch.