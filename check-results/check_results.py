#!/usr/bin/env python3


import argparse
import collections
import hashlib
import json
import os


DEFAULT_SUMS_FILE = 'sums'
DEFAULT_RESULTS_DIRECTORY = 'results'
DEFAULT_RANKED_GENES_FILE = 'ranked_genes_download.tsv'
DEFAULT_TOP_GENES_FILE = 'top_genes_download.tsv'
DEFAULT_COMBO_RESULTS_FILE = 'combo_results.txt'
DEFAULT_EDGE_FILE = '9606.STRING_experimental.edge'


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument('-s', '--sums_file', required=True)
    parser.add_argument('-d', '--results_directory')
    parser.add_argument('-r', '--ranked_genes_file')
    parser.add_argument('-t', '--top_genes_file')
    parser.add_argument('-c', '--combo_results_file')
    parser.add_argument('-e', '--edge_file')

    args = parser.parse_args()

    if args.results_directory is not None:
        if args.ranked_genes_file is None:
            args.ranked_genes_file = os.path.join(args.results_directory, DEFAULT_RANKED_GENES_FILE)
        if args.top_genes_file is None:
            args.top_genes_file = os.path.join(args.results_directory, DEFAULT_TOP_GENES_FILE)
        if args.combo_results_file is None:
            args.combo_results_file = os.path.join(args.results_directory, DEFAULT_COMBO_RESULTS_FILE)
        if args.edge_file is None:
            args.edge_file = os.path.join(args.results_directory, DEFAULT_EDGE_FILE)

    return args


def read_sums(sums_file):
    sums = collections.OrderedDict()

    with open(sums_file, 'r') as f:
        for line in f:
            line = line.rstrip()
            if line.startswith("#"):
                continue
            tokens = line.split()
            sha1sum = tokens[0]
            filename = tokens[1]
            sums[filename] = sha1sum

    return sums


def sha1_of_file(filepath):
    with open(filepath, 'rb') as f:
        return hashlib.sha1(f.read()).hexdigest()


def main():
    args = parse_args()

    # Read the known_good sums
    sums = read_sums(args.sums_file)
    #for f in sums:
    #    print(sums[f], f)

    # Compute the sums for the output files
    sha1s = collections.OrderedDict()
    for f in (args.ranked_genes_file, args.top_genes_file, args.combo_results_file, args.edge_file):
        f_basename = os.path.basename(f)
        sha1s[f_basename] = sha1_of_file(f)
    #for f in sha1s:
    #    print(sha1s[f], f)

    # Compute the results for the sums and the log
    results = collections.OrderedDict()
    log = []
    results['overall'] = True
    results['steps'] = collections.OrderedDict()
    for f in sums:
        if f not in sha1s or sha1s[f] != sums[f]:
            results['steps'][f] = False
            results['overall'] = False
            log.append("***sum for step/file %s is incorrect***" % (f))
        else:
            results['steps'][f] = True
            log.append("sum for step/file %s is correct" % (f))

    # Write results.json
    with open("results.json", 'w') as outfile:
        json.dump(results, outfile)

    # Write log.txt
    with open("log.txt", 'w') as outfile:
        for line in log:
            print(line, file=outfile)


if __name__ == "__main__":
    main()
