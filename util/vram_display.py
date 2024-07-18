def get_vram(file_path):
    try:
        with open(file_path, "r") as file:
            content = str(file.read())

            # Split by each clock tick
            content = content.split("\n")
            content = [x for x in content if x]

            for i in range(len(content)):
                # Split line into array
                content[i] = content[i].split(" ")[:-1]

                # Convert strings to base-16 (hex) ints
                for s in range(len(content[i])):
                    content[i][s] = int(content[i][s], 16)
            
            return content
    except FileNotFoundError:
        print(f"File not found: {file_path}")
    except Exception as e:
        print(f"An error occurred: {e}")


from tkinter import *
import time

master = Tk()

SCALE_FACTOR = 12
WIDTH = 64
HEIGHT = 32
DELAY = 2  # Delay in milliseconds

w = Canvas(master, width=WIDTH*SCALE_FACTOR, height=HEIGHT*SCALE_FACTOR, background="black")
w.pack()

def draw_vram():
    vram = get_vram("./output.txt")

    for frame in vram:
        # Clear the canvas
        w.delete("all")
        
        for y, row in enumerate(frame):
            for i in range(64):
                x = i

                pixel = (row >> x) & 1

                if pixel: 
                    w.create_rectangle(
                        x * SCALE_FACTOR, 
                        y * SCALE_FACTOR, 
                        (x * SCALE_FACTOR) + SCALE_FACTOR, 
                        (y * SCALE_FACTOR) + SCALE_FACTOR, 
                        fill="white"
                    )
        
        # Update the display
        w.update()
        
        # Wait for a short period
        time.sleep(DELAY / 1000.0)  # Convert delay to seconds

# Run the drawing function with a delay to simulate animation
master.after(0, draw_vram)

master.mainloop()
