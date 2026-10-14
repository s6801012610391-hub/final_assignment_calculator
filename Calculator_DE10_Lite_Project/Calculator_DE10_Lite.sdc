# 50 MHz DE10-Lite onboard clock (period 20.000 ns)
create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]
derive_clock_uncertainty
