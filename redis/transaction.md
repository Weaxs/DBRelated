# 示例1
  
    WATCH 1         #"OK"
    MULTI           #"OK"
    SET "2" 1       #"QUEUED"
    SET "1" 2       #"QUEUED"
    SET "3" 1       #"QUEUED"
    EXEC            
      # 1)  "OK"
      # 2)  "OK"
      # 3)  "OK"

# 示例2

    WATCH 1         "OK"
    SET "1" 1       "OK"
    MULTI           "OK"
    SET "2" 2       "QUEUED"
    SET "1" 3       "QUEUED"
    SET "3" 2       "QUEUED"
    EXEC            未返回 且事务中的三个SET一个也没执行

# 示例3
  
    MULTI           "OK"
    SET "2" 3       "QUEUED"
    SETNX "1" 2     "QUEUED"
    SET "3" 3       "QUEUED"
    EXEC
      1)  "OK"
      2)  "0"
      3)  "OK"
    SET "2" 和 "3" 都执行了

# 示例4

    MULTI           "OK"
    SET "2" 3       "QUEUED"
    NOTHISCOMMEND   "ERR wrong number of arguments for 'NOTHISCOMMEND' command"
    SET "3" 3       "QUEUED"
    EXEC            "EXECABORT Transaction discarded because of previous errors."
    SET "2" 3 未被执行

# 示例5

    MULTI           "OK
    SET "1" "ABC"   "QUEUED"
    INCR "1"        "QUEUED"
    SET "2" 1       "QUEUED"
    EXEC
       1)  "OK"
       2)  "ERR value is not an integer or out of range"
       3)  "OK"
    SET "1" 和 "2"均执行了
