def get_hex(file_path):
    try:
        with open(file_path, "rb") as file:
            content = file.read()
            return content.hex()
    except FileNotFoundError:
        print(f"File not found: {file_path}")
    except Exception as e:
        print(f"An error occurred: {e}")

def write_hex(file_path, data: str):
    try:
        with open(file_path, "w") as file:
            # add space every 2 chars (i.e., 6a02 --> 6a 02)
            data = " ".join(data[i:i+2] for i in range(0, len(data), 2))
            file.write(data)
    except FileNotFoundError:
        print(f"File not found: {file_path}")
    except Exception as e:
        print(f"An error occurred: {e}")

data = get_hex("../games/pong.rom")
write_hex("../games/pong_new.rom", data)

print("Done!")
