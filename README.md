This project was deeply inspired by [memcached](https://github.com/memcached/memcached), which has been widely used in production environment for long time. It is really great for large project, and can be easly extended because the network inter-process communication method. However, I think some relative small and host-standalone application can still greatly benefit from memory-based cache method, but the network inter-process communication seems much more heavy. So I create this project, hope for the general memory-based cache libray, offering simple interface, and can be link with any linux application conviently and more efficiently.   

Without the network part, the project can be simplified without libevent, CAS data intergration, information exchange protocal and so on, pthread_mutex_t seems enough for the sync purpose.   

Well, the code can not compare with the original memcached project for the quality and elegance, but I will try my best to refine it, and more test-cases are on the way. Any advance and pull request are welcome.   


# 1. Build   
```bash
user@gentoo minicached % make 
user@gentoo minicached % make -f Makefile_R
user@gentoo minicached % 
```
general make command will using the source/main.c and output a executable program as Debug/minicached, if you just need libminicached.a library, using the alternate make -f Makefile_R   
   
It is highly recommand for your own unit_test, for it is not strongly tested under production environment. You can install googletest and come to unit_test directory:   
```bash
user@gentoo minicached % cd unit_test 
user@gentoo unit_test % make
user@gentoo unit_test % ./minicached_unit_test 
```
If all went well, you will get the message like this:   
```bash
[----------] Global test environment tear-down
[==========] 6 tests from 6 test cases ran. (13002 ms total)
[  PASSED  ] 6 tests.
user@gentoo unit_test % 
```


# 2. General function and API offered   
This library is designed for general object cache, so the key and value is not stricted to char*, just tell the api your address and len, all will be done!   
Current apis cover as:   
```bash
mnc_item *mnc_new_item(const void *key, size_t nkey, time_t exptime, int nbytes);
mnc_item* mnc_get_item_l(const void* key, const size_t nkey);
void mnc_link_item_l(mnc_item *it);
void mnc_unlink_item_l(mnc_item *it);
RET_T mnc_store_item_l(mnc_item **it, const void* dat, const size_t ndata);
void mnc_remove_item(mnc_item *it);
void mnc_update_item(mnc_item *it, bool force);
```
The best tutorials are the test_cases. If you understand you can benefit from cached schema, I do believe you are smart enough to refer to the test_cases. Anyway, you can contact me if you wish.   

# 3. Examples or intergrated into your project   
## 3.1 Step to go   
(1) Tell the library which memory you give it dedicated, the unit is MB. just like   
```bash
user@gentoo unit_test % cat settings.json 
{
    "minicached":
    {
        "total_mem": 2,        // memory size, unit MB
    }
}
```
If you do not like this, just export the minicached_mem_limit and assign the proper value to it.   
(2) Call extern RET_T mnc_init(void);   
(3) Done!   

## 3.2 Example Code   
```c
static const char* cached_fetch_ques_text(ulong s_id, ulong msg_id, 
                                          P_MYSQL_CONN p_conn, char* store)
{
    mnc_item* it = NULL;
    char sql_buff[MAXLINESIZE];
    char str_buff[MAXLINESIZE];

    ulong key = msg_id << 8 | site_id_idx(site_id);
    it = mnc_get_item_l(&key, sizeof(ulong));
    if (it)
        return ITEM_dat(it);

    snprintf(sql_buff, sizeof(sql_buff), "SELECT m_txt FROM %s WHERE s_id=%lu AND uuid=%lu AND is_q=1;",
             get_mmap_tname(site_id), site_id, msg_id);
    if(mysql_fetch_string(&p_conn->mysql, sql_buff, str_buff) == RET_YES)
    {
        it = mnc_new_item(&key, sizeof(ulong), 6000/*10min*/, strlen(str_buff)+1);
        if (it)
        {
            mnc_store_item_l(&it, str_buff, strlen(str_buff)+1);
            return ITEM_dat(it);
        }

        st_d_print("!!!Error for allocate new mnc_item!!!");
        strcpy(store, str_buff);
    }
    else
    {
        *store = '\0';
    }

    return NULL;
}
```