create table twitter_url (
    id          serial primary key,
    url         varchar(512) not null,
    screen_name varchar(255),
    tweet       text,
    status      smallint not null default 1,
    created_on  timestamp,
    updated_on  timestamp
) ;

-- status 1:list, 2:saved

create unique index idx_url on twitter_url(url) ;

-- alter table twitter_url add column status smallint not null default 1 ;

