import csv

with open('fpga_pinmap_temp.xdc', 'w') as xdcfile:
    with open('mps4_pins.csv', newline='') as csvfile:
        csvreader = csv.DictReader(csvfile)
        for row in csvreader:
            row['Signal'] = row['Signal'].replace('<','[')
            row['Signal'] = row['Signal'].replace('>',']')
            row['IOStandard'] = row['IOStandard'].replace('(Default)', '')
            xdcfile.write("set_property IOSTANDARD %s [get_ports %s] \n" % (row['IOStandard'], row['Signal']))
            xdcfile.write("set_property PACKAGE_PIN %s [get_ports %s] \n" % (row['\ufeffNumber'], row['Signal']))