import os

def download():
    template = "https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2022-{month:02d}.parquet"

    for m in range(1, 13):
        query = "wget -c " + template.format(month=m)
        print("Downloading > ", query)
        os.system(query)

if __name__ == "__main__":
    download()