*** Usefull Commands 
CONNECT to CLI : docker exec -it redis_redis_1 redis-cli

REDIS GET VALUES COMMAND :
- if value is of type string -> GET <key>
- if value is of type hash -> HGETALL <key>
- if value is of type lists -> lrange <key> <start> <end>
- if value is of type sets -> smembers <key>
- if value is of type sorted sets -> ZRANGEBYSCORE <key> <min> <max>

display all keys : KEYS *

REMOVE KEYS : DEL *
