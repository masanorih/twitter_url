create table twitter_url (
    id          serial primary key,
    url         varchar(512) not null,
    screen_name varchar(255),
    tweet       text,
    created_on  timestamp,
    updated_on  timestamp
) ;

create unique index idx_url on twitter_url(url) ;

