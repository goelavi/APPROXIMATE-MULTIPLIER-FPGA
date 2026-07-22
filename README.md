8-bit Approximate Multiplier

This is a Verilog implementation of an approximate 8x8 unsigned multiplier, built on top of a 4x4 approximate multiplier block. I based the design on the approximate 4:2 compressor + encoded partial products idea from this paper:

Ansari, Jiang, Cockburn, Han - "Low-Power Approximate Multipliers Using Encoded Partial Products and Approximate Compressors", IEEE JETCAS 2018. (https://doi.org/10.1109/JETCAS.2018.2832204)



Why approximate multipliers

Exact multipliers are expensive in hardware - a lot of the cost comes from reducing the partial product array. For applications that can tolerate some error (image processing, ML inference, DSP stuff), you can approximate the compressor logic in the reduction tree and save a good chunk of area/power for a small, bounded accuracy hit. This project was mainly me trying to actually implement one of these designs at the RTL level instead of just reading about them.


How the 8x8 is built

Instead of approximating the full 8x8 array directly, I split each 8-bit operand into two 4-bit halves and built the 8x8 multiplier out of four 4x4 multiplies, added together with the right shifts:

<img width="574" height="544" alt="image" src="https://github.com/user-attachments/assets/571e78ca-082a-4112-949b-64f9da444e4b" />



All four partial products use the same approximate 4x4 block, including the most significant one (PP3). In the paper's naming this is closest to their "M8-1" configuration - the most hardware-efficient of the six 8x8 variants they propose, since none of the partial products fall back to an exact multiplier.

The approximate 4x4 block

This is where the actual approximation happens. Quick rundown of what each stage does (bit 0 = LSB):


- Bit 0 - just pp0,0, nothing to do.
- Bit 1 - two terms (pp0,1, pp1,0), so a plain half adder is enough, no approximation needed.
- Bits 2-4 - this is the interesting part. Instead of feeding the raw partial product bits into a 4:2 compressor, the symmetric pairs get pre-combined into propagate/generate style signals first:

<img width="570" height="74" alt="image" src="https://github.com/user-attachments/assets/38c0154b-60c5-4db2-8c5b-5290321d7c73" />



The approximate compressor itself is stripped down (no XOR, no Cout - both are dropped since they barely affect accuracy but cost extra gates), so on its own it's pretty inaccurate. But once you encode the inputs this way, a lot of the "wrong" rows in the compressor's truth table become inputs that can never actually occur, so the real-world error rate ends up way lower than the raw truth table would suggest. That's basically the whole trick of the paper.
- Bit 5 - here the design uses an exact full adder to combine pp2,3, pp3,2 and the carry coming in from the earlier stages. This is what makes it the "M1" variant specifically (the paper also has an "M2" variant that just drops this carry instead, trading a bit of accuracy for a shorter critical path).
- Bit 6 - exact half adder.
- Bit 7 - just the final carry out.
So exact logic on the edges (bits 0, 1, 5, 6, 7), approximate compressors in the middle (bits 2-4) where there's the most reduction happening and the most to gain from cutting gates.


A bug I found while verifying

When I first wrote a testbench and ran it across all 65536 input combinations, I was getting a 96% error rate and an MRED of 1.23, which is way higher than what the paper reports for this kind of design (they report roughly 73% ER / 0.065 MRED for the closest equivalent config). That's a big enough gap that something was clearly wrong, not just "approximation is lossy."

Tracked it down to one line:

<img width="534" height="80" alt="image" src="https://github.com/user-attachments/assets/0c0912af-7236-4236-a428-2095bba832d5" />



The carry c2 from stage 2 was getting inverted before being used in stage 3's sum, which isn't what the paper's derivation has. Removing the ~ brought the numbers back in line with the reference (72.58% ER, 0.0606 MRED), so I'm fairly confident this was just a typo rather than some clever simplification.

Results

Hardware (Xilinx Vivado synthesis):

- LUTs before optimization: 84
- LUTs after optimization: 55
- ~34.5% reduction vs baseline


Accuracy (exhaustive check, all 65536 input pairs, after the fix above):


- Error rate: 72.58%
- MRED: 0.0606
- Max absolute error: 10404

These accuracy numbers line up closely with what the paper reports for the same class of design, which is a decent sanity check that the RTL is actually doing what it's supposed to.

Reference

M. S. Ansari, H. Jiang, B. F. Cockburn, J. Han, "Low-Power Approximate Multipliers Using Encoded Partial Products and Approximate Compressors," IEEE Journal on Emerging and Selected Topics in Circuits and Systems, 2018.






