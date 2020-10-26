import itertools
import multiprocessing

def worker(filename):
    pass   # do something here!

def main():
    with multiprocessing.Pool(48) as Pool: # pool of 48 processes

        walk = os.walk("some/path")
        fn_gen = itertools.chain.from_iterable((os.path.join(root, file)
                                                for file in files)
                                               for root, dirs, files in walk)

        results_of_work = pool.map(worker, fn_gen) # this does the parallel processing


if __name__ == "__main__":
    main()
