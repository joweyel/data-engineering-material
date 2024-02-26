import os

URL_PREFIX = "https://d37ci6vzurychx.cloudfront.net/trip-data/{service}_tripdata_{year}-{month:02}.parquet"

def download(service, year):

    for m in range(1, 13):
        fmonth = f"{m:02d}"
        URL = URL_PREFIX.format(service=service, year=year, month=fmonth)

        local_prefix = f"data/raw/{service}/{year}/{fmonth}"
        local_file = f"{service}_tripdata_{year}_{fmonth}.parquet"
        local_path = f"{local_prefix}/{local_file}"

        print(f"Downloading {URL} to {local_path}")
        os.system(f"mkdir -p {local_prefix}")
        os.system(f"wget -c {URL} -O {local_path}")


if __name__ == "__main__":
    service = ["green", "yellow"]
    year = [2020, 2021]
    for s in service:
        for y in year:
            download(service=s, year=y)