function A = rx_params()
% RX_PARAMS  Receiver wired to the TX antenna terminals (as in Stage A): no antenna of its own.
A.R      = 50;
A.BW_Hz  = 20e6;
A.NF_dB  = 6;
A.cable_loss_dB = 0;
end
