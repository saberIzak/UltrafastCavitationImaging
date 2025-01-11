

This repository contains a MATLAB script based on Verasonics example scripts, modified to capture cavitation bubble dynamics.

Key Features:
Superframe Concept:
The code utilizes the concept of a superframe, where all the data for multiple imaging frames is stored in a single superframe. This approach ensures that:

All data is collected continuously during imaging.
The data transfer to the host computer occurs only after the entire superframe is completed.
Purpose:
By deferring data transfer until the superframe is complete, the code eliminates transfer time during imaging, enabling the capture of fast cavitation bubble dynamics.