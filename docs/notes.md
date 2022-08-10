# System setup notes and observations

## OctoPrint-PSUControl

To work with a simple relay control, likely this repo needs to be forked and
the following changes made:
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
