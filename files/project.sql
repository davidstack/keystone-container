use keystone;
update project set name='kube-system' where name='admin' and domain_id='default';
update user u,project p set u.default_project_id=p.id  where p.domain_id='default';