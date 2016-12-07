#ifndef ___KISSSDB_H
#define ___KISSSDB_H

#include<stdio.h>
#include<stdint.h>

#define DB_IO_ERROR 1
#define DB_INVALID_PARAMETER_ERROR 2
#define DB_KEY_NOT_FOUND 3

const uint32_t magic = ('k' << 24) | ('s' << 16) | ('d' << 8) | ('b');
typedef struct {
    FILE *f;
    uint32_t size;
} DB;

typedef struct {
    uint32_t magic;
    uint32_t size;
} Header;

typedef uint64_t Record;

typedef struct {
    uint32_t key_size;
    uint32_t val_size;
} EntryHeader;

extern int DB_create(const char *path, uint32_t hash_table_size);
extern int DB_open(DB *db, const char *path);
extern void DB_close(DB *db);
extern int DB_get(DB *db, const void *key, uint32_t keysize, char **value, uint32_t *cur_val_size);
extern int DB_add(DB *db, const void *key, uint32_t keysize, const void *value, uint32_t valsize);
#endif
