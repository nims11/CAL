#include "kisssdb.h"

#include <malloc.h>
#include <string.h>
#include <stdlib.h>
/* djb2 hash function
 * Copied from https://github.com/adamierymenko/kissdb/
 */
static uint64_t DB_hash(const void *b,unsigned long len){
    unsigned long i;
    uint64_t hash = 5381;
    for(i=0;i<len;++i)
        hash = ((hash << 5) + hash) + (uint64_t)(((const uint8_t *)b)[i]);
    return hash;
}

int DB_create(const char *path, uint32_t hash_table_size){
    FILE *f = fopen(path, "wb");
    uint32_t iter;
    if(!f){
        return DB_IO_ERROR;
    }
    if(fseeko(f, 0, SEEK_END)){
        fclose(f);
        return DB_IO_ERROR;
    }
    if(!hash_table_size){
        fclose(f);
        return DB_INVALID_PARAMETER_ERROR;
    }

    if(fseeko(f, 0, SEEK_SET)){fclose(f); return DB_IO_ERROR;}
    else{
        Header header = {magic, hash_table_size};
        if(fwrite(&header, sizeof(Header), 1, f) != 1){fclose(f); return DB_IO_ERROR;}
        for(iter = 0;iter < hash_table_size; iter++){
            Record record = 0;
            if(fwrite(&record, sizeof(Record), 1, f) != 1){fclose(f); return DB_IO_ERROR;}
        }
    }

    fclose(f);
    return 0;
}

int DB_open(DB *db, const char *path){
    FILE *f = fopen(path, "r+b");
    db->f = f;
    if(!f){
        return DB_IO_ERROR;
    }
    if(fseeko(f, 0, SEEK_END)){
        fclose(f);
        return DB_IO_ERROR;
    }
    if(fseeko(f, 0, SEEK_SET)){fclose(f); return DB_IO_ERROR;}
    else{
        Header header;
        fread(&header, sizeof(Header), 1, f);
        db->size = header.size;
    }
    return 0;
}

int DB_add(DB *db, const void *key, uint32_t keysize, const void *value, uint32_t valsize){
    EntryHeader entry_header = {keysize, valsize};
    Record record;
    uint64_t hash = DB_hash(key, keysize) % db->size;
    uint64_t offset = sizeof(Header) + sizeof(Record)*hash;
    uint64_t prev_offset;
    if(fseeko(db->f, offset, SEEK_SET)) return DB_IO_ERROR;
    prev_offset = ftello(db->f);
    fread(&record, sizeof(Record), 1, db->f);
    while(record > 0){
        if(fseeko(db->f, record, SEEK_SET)) return DB_IO_ERROR;
        prev_offset = ftello(db->f);
        fread(&record, sizeof(Record), 1, db->f);
    }
    fseeko(db->f, 0, SEEK_END);
    offset = ftello(db->f);
    record = 0;
    fwrite(&record, sizeof(Record), 1, db->f);
    fwrite(&entry_header, sizeof(EntryHeader), 1, db->f);
    fwrite(key, keysize, 1, db->f);
    fwrite(value, valsize, 1, db->f);
    fseeko(db->f, prev_offset, SEEK_SET);
    record = offset;
    fwrite(&record, sizeof(Record), 1, db->f);
    return 0;
}

int DB_get(DB *db, const void *key, uint32_t keysize, char **value, uint32_t *cur_val_size){
    EntryHeader entry_header;
    uint64_t iter = 0;
    Record record;
    uint64_t hash = DB_hash(key, keysize) % db->size;
    uint64_t offset = sizeof(Header) + sizeof(Record)*hash;
    if(fseeko(db->f, offset, SEEK_SET)) return DB_IO_ERROR;
    fread(&record, sizeof(Record), 1, db->f);
    while(record > 0){
        int match = 1;
        if(fseeko(db->f, record, SEEK_SET)) return DB_IO_ERROR;
        fread(&record, sizeof(Record), 1, db->f);
        fread(&entry_header, sizeof(EntryHeader), 1, db->f);
        if(keysize != entry_header.key_size)continue;
        for(iter = 0 ;iter < keysize && match; iter++){
            char ch = getc(db->f);
            if(ch != ((char*)key)[iter]) match = 0;
        }
        if(!match)
            continue;
        if(*cur_val_size < entry_header.val_size){
            *cur_val_size = entry_header.val_size+1;
            *value = realloc(*value, *cur_val_size);
        }
        for(iter = 0; iter < entry_header.val_size; iter++){
            (*value)[iter] = getc(db->f);
        }
        return 0;
    }
    return DB_KEY_NOT_FOUND;
}

void DB_close(DB *db){
    fclose(db->f);
}

#define BUFSIZE 1000000
char buffer[BUFSIZE];
int inp_line(char **str, uint32_t *cur_size){
    uint32_t len = 0;
    while(fgets(buffer, sizeof(buffer), stdin)){
        uint32_t buf_len = strlen(buffer);
        if(buf_len + len + 1 > *cur_size){
            *cur_size += BUFSIZE;
            char *extra = (char*)realloc(*str, *cur_size);
            *str = extra;
        }
        strcpy((*str)+len, buffer);
        len += buf_len;
        (*str)[len] = 0;
        if((*str)[len-1] == '\n'){
            (*str)[len-1] = 0;
            break;
        }
    }
    return len;
}

int main(int argc, char **argv){
    DB db;
    uint32_t cur_key_size = 1000;
    uint32_t cur_val_size = 1000000;
    char *key = malloc(cur_key_size);
    char *val = malloc(cur_val_size);
    if(argc == 3){
        DB_create(argv[1], atoi(argv[2]));
        DB_open(&db, argv[1]);
        while(inp_line(&key, &cur_key_size)){
            inp_line(&val, &cur_val_size);
            DB_add(&db, key, strlen(key)+1, val, strlen(val)+1);
        }
        DB_close(&db);
    }else if(argc == 2){
        DB_open(&db, argv[1]);
        while(inp_line(&key, &cur_key_size)){
            fflush(stdin);
            if(DB_get(&db, key, strlen(key)+1, &val, &cur_val_size)){
                printf("\n");
            }else
                printf("%s\n", val);
        }
        DB_close(&db);
    }
    free(key);
    free(val);
    return 0;
}
