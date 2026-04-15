import re


def generate_pad_instances(input_file, output_file):
    # Define patterns for parsing
    pattern = r'(\binput\b|\boutput\b)\s*(?:\[(\d+):(\d+)\])?\s*([A-Z_][A-Z0-9_]*)'


    # Read input file
    with open(input_file, 'r') as file:
        lines = file.readlines()


    pad_instances = []


    for line in lines:
        line = line.strip()


        matches = re.findall(pattern, line)
        for direction, msb, lsb, signal in matches:
            if msb:  # Handle vectors
                width = int(msb) - int(lsb) + 1
                if direction == 'input':
                    pad_instances.append(
                        f'generate\n'
                        f'    genvar i;\n'
                        f'    for (i = 0; i < {width}; i = i + 1) begin : gen_{signal.lower()}\n'
                        f'        PDDW08DGZ_H_G pad_in_{signal.lower()}_i (.I(), .OEN(1), .REN(0), .PAD({signal}[i]), .C({signal.lower()}[i]));\n'
                        f'    end\n'
                        f'endgenerate\n'
                    )
                elif direction == 'output':
                    pad_instances.append(
                        f'generate\n'
                        f'    genvar i;\n'
                        f'    for (i = 0; i < {width}; i = i + 1) begin : gen_{signal.lower()}\n'
                        f'        PDDW08DGZ_H_G pad_out_{signal.lower()}_i (.I({signal.lower()}[i]), .OEN(0), .REN(0), .PAD({signal}[i]), .C());\n'
                        f'    end\n'
                        f'endgenerate\n'
                    )
            else:  # Handle scalars
                if direction == 'input':
                    pad_instances.append(
                        f'PDDW08DGZ_H_G pad_in_{signal.lower()} (.I(), .OEN(1), .REN(0), .PAD({signal}), .C({signal.lower()}));'
                    )
                elif direction == 'output':
                    pad_instances.append(
                        f'PDDW08DGZ_H_G pad_out_{signal.lower()} (.I({signal.lower()}), .OEN(0), .REN(0), .PAD({signal}), .C());'
                    )

    # Write to output file
    with open(output_file, 'w') as file:
        for instance in pad_instances:
            file.write(instance + '\n')


input_file = './cln16fcll_io_map.txt'  # Input file name
output_file = 'pad_instances.txt'  # Output file name


generate_pad_instances(input_file, output_file)