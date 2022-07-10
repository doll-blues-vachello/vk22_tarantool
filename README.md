# Tarantool (10, 20, 40 баллов)

## Установка
- установить libvips, libvips-dev, unzip (для ubuntu: ``sudo apt-get -y install libvips libvips-dev unzip``)
- установить lua библиотеки:```tarantoolctl rocks install --server=https://luarocks.org/ multipart && tarantoolctl rocks install http && tarantoolctl rocks install --server=https://luarocks.org/ lua-vips```
- создать папку ``data``

## Запуск
``tarantool main.lua``

## Использование
Все ссылки приведены для поднятого сервиса [http://dollblues.kheynov.ru:1337](http://dollblues.kheynov.ru:1337)
### Добавление мема (10 баллов)
```
curl --location --request POST 'http://dollblues.kheynov.ru:1337/set' \
--form 'top="Top text"' \
--form 'bottom="Bottom text"' \
--form 'image=@"path_to_image.png"'
```
### Просмотр мема (10 баллов)
``` 
http://dollblues.kheynov.ru:1337/get?id=<meme_id>
```
Пимер - 
[http://dollblues.kheynov.ru:1337/get?id=1](http://dollblues.kheynov.ru:1337/get?id=1)

### Страница со случайным мемом (40 баллов)
[http://dollblues.kheynov.ru:1337/index.html](http://dollblues.kheynov.ru:1337/index.html)

### Поиск id мема по тексту (20 баллов)
```
curl --location --request POST 'http://dollblues.kheynov.ru:1337/set' \
--form 'top="Top text"' \
--form 'bottom="Bottom text"'
```