# PassManager

## Members :

* Jawad FRASNI
* Yannis BOUKARI
* Anthony DELGEHIER
* Tom SAUNIER

## Requirement :

### SFTP Server

You need to have access to a SFTP Server. You need to read and write in your home directory.

### Xclip

```
# apt install xclip
```

## Installation

* Clone this repository

```
$ git clone https://github.com/Tom4599/epsi-password-manager.git
```

* Create symlink

```
$ chmod +x /absolute/path/to/executable/passmanager.sh
$ ln -s /absolute/path/to/executable/passmanager.sh /usr/local/bin/passmanager.sh
```

## Configuration

### Initialization

```
$ ./passmanager.sh init
 Creating directories...
 OK
 Generating conf file...
 OK
 Generating keys...
Generating RSA private key, 2048 bit long modulus (2 primes)
........................................+++++
.................................+++++
e is 65537 (0x010001)
writing RSA key
 OK
 Applying rights...
 OK
```

### File configuration

You need to fill your configuration file.

* Example

```
$ cat ~/.passmanager/passmanager.conf
## Conf file for netpaste
Name: tosau
SFTPHost: example.com
SFTPPort: 2022
SFTPUser: tom
```

### Add user

To share with a friend you need to have his public key.

* On friend's computer

```
$ ./passmanager.sh getpublickey
 Public Key :

-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0tV0BylfHskM8VxxM6K9
02zehVcmeQ6UjD5XV3kDV32cYr/3+DtPxxgPMAZQD1Tp0y8AM97PqLuw/keH3z5W
T7/nrOy7UlaYlVJXUILSuQ+B0wRmJQfO1lLbQKRKYooWgu2S84CFox0fD6oYa2qn
xks7PPWd9cAp5jF9E/HGgRFMaZ5eG+2ygU8Juhgiscbj7i21kUYzCiBhAoBNVccS
uU1kBO3cSkc2x8wmXl217dS4+Q+vKvr2iT9cW0FzP2F4+7pEEJTDnxM/R48w3ffu
/rp90/qo/8Rrp/6gfVArh+SkGr/2VBTNJMdIxYORTJvNgDShRmq4ncTk9+D2wK2R
GQIDAQAB
-----END PUBLIC KEY-----
```

He needs to send you this key and you need to **COPY** it.

* When you have copied it, run `passmanager.sh adduser <user>` on your computer.
* Give the user your friend use on his computer

After that your friend can share you password. If you want to share password to your friend, you have to do the same procedure in reverse.

### Add Password (only for you)

```
╰─ ❯ ./passmanager.sh addpwd gmail
Please enter allow users or group name (left empty if only you can access) and (separate them by a ',' if there is multiple user) :      
Please enter the password : monsuperpassword             

╰─ ❯ ./passmanager.sh listpwd
Titre                         | Creator             
**************************************************
NETFLIXkikus                  | guevarus            
gmail                         | tosau               
passforyabou                  | tosau               
passwordgoogle                | tosau               
testpassword2                 | tosau               

╰─ ❯ ./passmanager.sh getpwd gmail
Please enter the password creator : tosau
 Password gmail :

monsuperpassword
```

### Add password (for guevarus)

```
╰─ ❯ ./passmanager.sh addpwd epsi
Please enter allow users or group name (left empty if only you can access) and (separate them by a ',' if there is multiple user) : guevarus
Please enter the password : monautrepassword
```

## All functions

### GetPublicKey

```
╰─ ❯ ./passmanager.sh getpublickey
 Public Key :

-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4mRMpsUZFqA3a15niDJH
lBsI5jizIBj1k2/Nt/9Pjxr3CLv4QU0G8skkGrSVTqzUm1zuO16M/w9B98+V8qSf
2QaHezODF2Yb6FnxOfIatp3EBUk8ldT/Vx4J0TqY70LXNCLsQdINx58Y+SOVNqpN
VbPwZObg4KQo1f6Q6G/yxXZ3aNHydpYtV6haETXNSLJCCKsTR4j2MjStt0U4OAc3
/c3mDE6PYCvHoB6iOhIGF4B4rYuKgtozl+SqC1XGCnWfLrpOKxsMmOQ3afkY7iXn
TJXG8M5o5Aa5nXo6RcCnBq+Xxf9TXDL3Ou49/Scph7n2/YBzyK7HDVahd23M1rKq
iwIDAQAB
-----END PUBLIC KEY-----
```

### GetSftpPublicKey

```
╰─ ❯ ./passmanager.sh getsftppublickey
 SFTP Public Key :

---- BEGIN SSH2 PUBLIC KEY ----
Comment: "2048-bit RSA, converted by tosau@INITIA17 from OpenSSH"
AAAAB3NzaC1yc2EAAAADAQABAAABAQCySr0DXtRUKuEPIC25qqSbfWJnLlfhuZv5wUAtDR
Wc1xktn4CFwSQxIwYMD1MKTcPfkirm0AWvlRfD9g/Ce4HIg2vF6dao/C3Zb3SPXS2whDL5
161oJzwrQWvOneuXdbZMkZY/amFOa+hnP9hI8b3Wr9i5Q3izYCZq6z4rX/Sbd7UaP9UV8y
7W/HBFhWDZLXirYMCtekgBTC2LArOQeBU5bJ8IJVRTpwJWQCQusqdFc7b6DFQ7JEYwGBcG
g77E+CbSgDc8IXdocRJcOqCLIQLuYylMnVL9nEHWRplpSEvNrfSVyRxeQjso89pIHQBWW1
myk5lrgKNA0aMYkQOswiKZ
---- END SSH2 PUBLIC KEY ----
```

### Group

#### Create

```
╰─ ❯ ./passmanager.sh group add tobou 
Please enter the users list separated by , : tosau,guevarus
 Adding Group...
 OK
```

#### AddUser

```
╰─ ❯ ./passmanager.sh group adduser jawad tobou 
 Adding jawad to tobou...
 OK
```

#### DelUser

```
╰─ ❯ ./passmanager.sh group deluser jawad tobou
 Removing jawad from tobou...
 OK
```

### User

#### Add

```
╰─ ❯ ./passmanager.sh adduser guevarus 
Please copy the public key in your clipboard before press Enter 
 Adding User...
```

### Stats

```
╰─ ❯ ./passmanager.sh stat
 Group tobou :
tosau,guevarus


 Users :
guevarus
tosau
```
