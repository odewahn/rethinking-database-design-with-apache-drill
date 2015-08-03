# Drilling into Healthy Choices

Drill is a SQL-engine for everything (almost). From simple tabular data, to semi-structured to even the most complex structured JSON data. We will explore what Apache Drill can do and how it enables us to rethink database design to make everyone's life easier.  In the first half of this article, we will use the National Nutrient Database (NNDB) to illustrate how to explore a new database with Drill. The NNDB is convenient to use and is an openly available database, and, when coupled with Drill, you can use it without having to be a software engineer. There is no need to figure out how to transform and load data into a relational database just to query the data. You can even use Drill as a datasource within any application (e.g. Tableau, Microsoft Excel) which can connect to a database through a standard interface. Let’s get started.

## USDA National Nutrient Database

The National Nutrient Database (NNDB) is provided by the USDA to allow the public to get standardized information on foods. Documentation for the database and all supporting information on the [USDA website](http://www.ars.usda.gov/Services/docs.htm?docid=8964). Each release of the database and documentation receives a version number. At the time this article is published the current release is referred to as Standard Reference, Release 27 or SR27\. The table structures / file definitions do not appear to change dramatically over time. It is quite likely that the queries provided here will continue to work with future releases with little or no modifications.

The entire database can be downloaded in a [zipped package](http://www.ars.usda.gov/Services/docs.htm?docid=24912) of ASCII files. In order to follow along in a hands-on manner with the rest of this article / tutorial, you will want to download the zip file and extract the files to /tmp (or equivalent). Drill has a workspace named tmp which references the system’s respected temporary folder. When unzipping the files, ensure they are extracted into a folder named sr27asc. All of the commands below reference the tmp workspace and that folder name (e.g. /tmp/sr27asc).

### Starting and Configuring Drill to Handle the NNDB

To start your Drill instance you can use either of these two command lines:

```bash
> sqlline -u jdbc:drill:zk=local

# this is a shortcut for the previous line (linux/mac only)
> drill-embedded
```

First and foremost, it will be important for you to know that you can configure Drill via the web interface. The Drill configuration can be accessed at [http://localhost:8047/](http://localhost:8047/) after you start your Drill instance.

The NNDB uses characters that most people don’t use for delimited file formats. The fields are separated by carets (^) and text fields are surrounded by tildes (~). Because of this we need to add a little bit of configuration to enable Drill to properly read / parse these files. Paste this file format definition to the formats section of the dfs storage definition which can be found in Drill’s web interface under the storage menu option:

```javascript
"nndb": {
  "type": "text",
  "extensions": [ "txt" ],
  "quote": "~",
  "escape": "~",
  "delimiter": "^"
},
```

Next, let’s convert these tables into Parquet format to simplify the queries. As we do that, we can also add a workspace definition that has parquet as a default format and allows tables to be created. Workspaces are abbreviations are a way to access files or tables. Paste the definition below into the workspaces section of your dfs storage definition. Make sure that you change the location parameter to the directory where you want to store your tables.

```javascript
"nndb": {
  "location": "/opt/drill/nndb",
  "writable": true,
  "storageformat": "parquet"
},
  ```

## Creating Tables from Delimited Files

For Drill, delimited files are really just tables. They contain rows of data in a columnar form. Delimited files are very simple, but definitely not the most efficient format if you are going to be querying large volumes of data regularly. Delimited files can work great, but if size or speed ever become a concern you will be quickly be looking for alternative storage formats. For this use case, we are going to convert all of the delimited files to Parquet format with Drill.

The queries below do this conversion for each of the data files in the NNDB. Note how the source data columns do not have names and are referenced as columns[N], but are named as part of the create table query. Having named columns makes queries cleaner, easier to read and to understand. The table and column names we use here are taken from the original documentation for this dataset.

```sql
-- Referenced from Page 30 of the sr27_doc.pdf
create table dfs.nndb.food_des(NDB_No, FdGrp_Cd, Long_Desc, Shrt_Desc, ComName, ManufacName, Survey, Ref_desc, Refuse, SciName, N_Factor, Pro_Factor, Fat_Factor, CHO_Factor) as select columns[0], columns[1], columns[2], columns[3], columns[4], columns[5], columns[6], columns[7], columns[8], columns[9], columns[10], columns[11], columns[12], columns[13] from dfs.tmp.`sr27asc/FOOD_DES.txt`;

-- Referenced from Page 31 of the sr27_doc.pdf
create table dfs.nndb.fd_group(FdGrp_Cd, FdGrp_Desc) as select columns[0], columns[1] from dfs.tmp.`sr27asc/FD_GROUP.txt`;

-- Referenced from Page 31 of the sr27_doc.pdf
create table dfs.nndb.langual(NDB_No, Factor_Code) as select columns[0], columns[1] from dfs.tmp.`sr27asc/LANGUAL.txt`;

-- Referenced from Page 31-32 of the sr27_doc.pdf
create table dfs.nndb.langdesc(Factor_Code, Description) as select columns[0], columns[1] from dfs.tmp.`sr27asc/LANGDESC.txt`;

-- Referenced from Page 32-33 of the sr27_doc.pdf
create table dfs.nndb.nut_data(NDB_No, Nutr_No, Nutr_Val, Num_Data_Pts, Std_Error, Src_Cd, Deriv_Cd, Ref_NDB_No, Add_Nutr_Mark, Num_Studies, `Min`, `Max`, DF, Low_EB, Up_EB, Stat_cmt, AddMod_Date, CC) as select columns[0], columns[1], columns[2], columns[3], columns[4], columns[5], columns[6], columns[7], columns[8], columns[9], columns[10], columns[11], columns[12], columns[13], columns[14], columns[15], columns[16], columns[17] from dfs.tmp.`sr27asc/NUT_DATA.txt`;

-- Referenced from Page 34 of the sr27_doc.pdf
create table dfs.nndb.nutr_def(Nutr_No, Units, Tagname, NutrDesc, Num_Dec, SR_Order) as select columns[0], columns[1], columns[2], columns[3], columns[4], columns[5] from dfs.tmp.`sr27asc/NUTR_DEF.txt`;

-- Referenced from Page 34-35 of the sr27_doc.pdf
create table dfs.nndb.src_cd(Src_Cd, SrcCd_Desc) as select columns[0], columns[1] from dfs.tmp.`sr27asc/SRC_CD.txt`;

-- Referenced from Page 35 of the sr27_doc.pdf
create table dfs.nndb.deriv_cd(Deriv_Cd, Deriv_Desc) as select columns[0], columns[1] from dfs.tmp.`sr27asc/DERIV_CD.txt`;

-- Referenced from Page 36 of the sr27_doc.pdf
create table dfs.nndb.weight(NDB_No, Seq, Amount, Msre_Desc, Gm_Wgt, Num_Data_Pts, Std_Dev) as select columns[0], columns[1], columns[2], columns[3], columns[4], columns[5], columns[6] from dfs.tmp.`sr27asc/WEIGHT.txt`;

-- Referenced from Page 36-37 of the sr27_doc.pdf
create table dfs.nndb.footnote(NDB_No, Footnt_No, Footnt_Typ, Nutr_No, Footnt_Txt) as select columns[0], columns[1], columns[2], columns[3], columns[4] from dfs.tmp.`sr27asc/FOOTNOTE.txt`;

-- Referenced from Page 37 of the sr27_doc.pdf
create table dfs.nndb.datsrcln(NDB_No, Nutr_No, DataSrc_ID) as select columns[0], columns[1], columns[2] from dfs.tmp.`sr27asc/DATSRCLN.txt`;

-- Referenced from Page 37-38 of the sr27_doc.pdf
create table dfs.nndb.data_src(DataSrc_ID, Authors, Title, `Year`, Journal, Vol_City, Issue_State, Start_Page, End_Page) as select columns[0], columns[1], columns[2], columns[3], columns[4], columns[5], columns[6], columns[7], columns[8] from dfs.tmp.`sr27asc/DATA_SRC.txt`;
```

If you put all these queries in a file called nndb.sql, then you could have Drill run all of these commands at one time:

```bash
 > drill-embedded --run=nndb.sql
```

Otherwise, just paste them all into the command line and they will run in order. This should take about 15 seconds.

## Working with the Data

Now that we have the data in a convenient form, we are free to do anything our hearts desire with this dataset. From inside Drill, you can refer to these tables as dfs.nndb.TABLE_NAME. This means that the new database files which contain the data from the original files is now in the directory you associated with the nndb workspace when you configured the nndb workspace.

Here is an entity relationship diagram (ERD) which should make querying this data a little easier.



