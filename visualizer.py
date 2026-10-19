
import os
import matplotlib.pyplot as plt
import numpy as np

SCREEN_WIDTH = 128
SCREEN_HEIGHT = 64

display_matrix = np.zeros((SCREEN_HEIGHT, SCREEN_WIDTH))

log_path = "pixel_stream.txt"
if not os.path.exists(log_path):
    print(f"Err")
    exit(1)

pixel_count = 0
with open(log_path, "r") as file:
    for line in file:
        if "," in line:
            try:
                row_str, col_str = line.strip().split(",")
                row = int(row_str)
                col = int(col_str)
                
                if (0 <= row < SCREEN_HEIGHT) and (0 <= col < SCREEN_WIDTH):
                    display_matrix[row, col] = 1.0  
                    pixel_count += 1
            except ValueError:
                continue

print("loaded:", pixel_count) 


plt.imshow(display_matrix, cmap='cool', interpolation='nearest')

plt.axis('off')  

# Save the final image output file natively to your main folder workspace
output_image = "virtual_hud_output.png"
plt.savefig(output_image, bbox_inches='tight', facecolor='black')

