# System setup notes and observations

## OctoPrint-PSUControl

Since the **udev** dynamic allocation of `/dev/ttyANYCUBIC` causes a restart of
the docker s6 services, the default behaviour of PSUControl plugin is to reset
the state of the printer which would turns it back off.

To work with a simple relay control that preserves the printer power state,
likely the `OctoPrint-PSUControl` repo needs to be forked
and the following changes made:

* `configure_gpio` function in `octoprint_psucontrol/__init__.py`:

    ```
    if self.config['switchingMethod'] == 'GPIO':
        # original logic prior to try...
        
        if (self.config['sensingMethod'] == 'GPIO' and
            self.config['senseGPIOPin'] == self.config['onoffGPIOPin']):
            # Get initial state as initial_output
            try:
                pin = periphery.GPIO(self.config['GPIODevice'],
                                     self.config['onoffGPIOPin'],
                                     'in')
                initial_output = 'high' if pin.read() else 'low'
                self.configuredGPIOPins['sense'] = pin
            except Exception as err:
                self._logger.exception(err)
        
        try:
            # original try/except logic...
    
    if self.config['sensingMethod'] == 'GPIO':
        if self.config['senseGPIOPin'] != self.config['onoffGPIOPin']:
            # original sensingMethod logic
    ```
