# Homework

The notebook to the homework can be found [here](homework_solution.ipynb).

## Question 1:
What is the sum of the outputs of the generator for `limit = 5`?

- **A**: 10.23433234744176
- **B**: 7.892332347441762
- **C**: 8.382332347441762
- **D**: 9.123332347441762

**Solution**:
- **C**: 8.382332347441762
```python
sum([val for val in square_root_generator(limit)])
```

## Question 2: 
What is the 13th number yielded by the generator?

- **A**: 4.236551275463989
- **B**: 3.605551275463989
- **C**: 2.345551275463989
- **D**: 5.678551275463989

**Solution**:
- **B**: 3.605551275463989
```python
idx = 1
for val in square_root_generator(limit=14):
    print(f"{idx} - {val}")
    idx += 1
```

## Question 3:
Append the 2 generators. After correctly appending the data, calculate the sum of all ages of people.

- **A**: 353
- **B**: 365
- **C**: 378
- **D**: 390

**Solution**:
- **A**: 353
```python
people_pipeline = dlt.pipeline(
    destination="duckdb",
    dataset_name='people'
)

info = people_pipeline.run(
    people_1(),
    table_name="people_1",
    write_disposition="replace"
)

conn = duckdb.connect(f"{people_pipeline.pipeline_name}.duckdb")
conn.sql(f"SET search_path = '{people_pipeline.dataset_name}'")

info = people_pipeline.run(
    people_2(),
    table_name="people_1",
    write_disposition="append"
)

age_sum = conn.sql("SELECT SUM(age) FROM people_1").fetchone()[0]
print(age_sum)
```


## Question 4: 
Merge the 2 generators using the ID column. Calculate the sum of ages of all the people loaded as described above.

- **A**: 215
- **B**: 266
- **C**: 241
- **D**: 258

**Solution**:
- **B**: 266
```python
# Create table from people_1 ganerator
info = people_pipeline.run(
    people_1(),
    table_name="people_3",
    write_disposition="replace"
)

# Merge people_2 generator on the ley `ID`
info = people_pipeline.run(
    people_2(),
    table_name="people_3",
    write_disposition="merge",
    primary_key="ID"
)

conn = duckdb.connect(f"{people_pipeline.pipeline_name}.duckdb")
conn.sql(f"SET search_path = '{people_pipeline.dataset_name}'")

print("COUNT: ", conn.sql("SELECT COUNT(*) FROM people_3").fetchone()[0])
print("SUM: ", conn.sql("SELECT SUM(age) FROM people_3").fetchone()[0])
```