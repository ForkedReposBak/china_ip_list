import sys


def ip_to_str(ip):
    _ip = [None] * 4
    _ip[0] = (ip & 0xff000000) >> 24
    _ip[1] = (ip & 0x00ff0000) >> 16
    _ip[2] = (ip & 0x0000ff00) >> 8
    _ip[3] = (ip & 0x000000ff)

    return '.'.join([str(i) for i in _ip])


def convert_to_seg(ip):
    ip, mask_len = ip.split('/')
    ip = sum([int(part_ip) * 256**(3 - i)
              for i, part_ip in enumerate(ip.split('.'))])

    mask_len = int(mask_len)

    low_mask = 0xffffffff << (32 - mask_len)
    low_ip = ip_to_str((ip & low_mask) + 1)

    high_mask = 0xffffffff >> mask_len
    high_ip = ip_to_str(ip | high_mask)

    return ' '.join((low_ip, high_ip))


if __name__ == '__main__':
    read_file_name = '/home/china_ip_list/china_ipv4_list'
    write_file_name = '/home/china_ip_list/SSR/chn_ip.txt'

    chn_ip_list_file = []
    with open(read_file_name, 'r') as f:
        for line in f:
            line = line.strip()
            chn_ip_list_file.append(convert_to_seg(line))
    i = 1
    total = len(chn_ip_list_file)
    fileObject = open(write_file_name, 'w')
    for ip in chn_ip_list_file:
        fileObject.write(ip)
        if i < total:
            fileObject.write('\n')
        i += 1
    fileObject.close()
