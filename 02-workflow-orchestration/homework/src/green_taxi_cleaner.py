if 'transformer' not in globals():
    from mage_ai.data_preparation.decorators import transformer
if 'test' not in globals():
    from mage_ai.data_preparation.decorators import test


@transformer
def transform(data, *args, **kwargs):
    ## Removing "bad" data

    # Removing rows where passenger count is 0
    passenger_filter = data["passenger_count"] > 0
    # Removing rows where trip-distance is 0
    distance_filter = data["trip_distance"] > 0

    data = data[passenger_filter & distance_filter]

    ## Creating a date-column that can be used 
    ## for slitting transformer outputs
    data["lpep_pickup_date"] = data["lpep_pickup_datetime"].dt.date

    ## CamelCase to Snake_Case
    cc2sc = {
        "VendorID": "vendor_id",
        "RatecodeID": "ratecode_id",
        "PULocationID": "pu_location_id",
        "DOLocationID": "do_location_id",
    }
    data.rename(columns=cc2sc, inplace=True)

    print(data.shape[0])

    return data


@test
def test_output(output, *args) -> None:
    """
    Template code for testing the output of the block.
    """
    assert output is not None, 'The output is undefined'

@test
def test_vendor_id(output, *args) -> None:
    """
    Check if `vendor_id` is in dataframe
    """
    assert "vendor_id" in output

@test
def test_passenger_count(output, *args) -> None:
    """
    Check if there are no 0-passenger trips (all > 0)
    """
    assert (output['passenger_count'] > 0).all()

@test
def test_trip_distance(output, *args) -> None:
    """
    Check if there are no 0-distance trips (all > 0)
    """
    assert (output['trip_distance'] > 0).all()