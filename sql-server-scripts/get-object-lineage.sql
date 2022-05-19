create or alter procedure [#GetObjectLineage](
    @object nvarchar(max)
)
as
declare
    @objectId int
begin
    set xact_abort, nocount on;
    set transaction isolation level read committed;

    if object_id(@object) is not null
    begin
        set @objectId = object_id(@object);
    end;
    else if isnumeric(@object) = 1 and object_name(@object) is not null
    begin
        set @objectId = cast(@object as integer);
    end;
    else
    begin
        raiserror(N'Cannot find object with name or id "%s".', 16, 1, @object);
    end;

    with
        [AllDependencies] as (
            select distinct [object_id], [referenced_major_id]
            from [sys].[sql_dependencies]
        ),
        [Uses] as (
            select
                cast(N'Uses' as nvarchar(max))              as [dependecy_type],
                0                                           as [dependecy_depth],
                [D].[referenced_major_id]                   as [object_id]
            from [AllDependencies] as [D]
            where [D].[object_id] = @objectId

            union all

            select
                cast(N'UsesIndirectly' as nvarchar(max))    as [dependecy_type],
                [U].[dependecy_depth] + 1                   as [dependecy_depth],
                [D].[referenced_major_id]                   as [object_id]
            from [AllDependencies] as [D]
                inner join [Uses] as [U]
                    on [D].[object_id] = [U].[object_id]
        ),
        [UsedBy] as (
            select
                cast(N'UsedBy' as nvarchar(max))            as [dependecy_type],
                0                                           as [dependecy_depth],
                [D].[object_id]                             as [object_id]
            from [AllDependencies] as [D]
            where [D].[referenced_major_id] = @objectId

            union all

            select
                cast(N'UsedByIndirectly' as nvarchar(max))  as [dependecy_type],
                [U].[dependecy_depth] + 1                   as [dependecy_depth],
                [D].[object_id]                             as [object_id]
            from [AllDependencies] as [D]
                inner join [UsedBy] as [U]
                    on [D].[referenced_major_id] = [U].[object_id]
        ),
        [ObjectDependencies] as (
            select * from [Uses] 
            union all
            select * from [UsedBy]
        )
    select distinct
        [D].[dependecy_type]        as [dependecy_type],
        [D].[dependecy_depth]       as [dependecy_depth],
        [O].[type_desc]             as [object_type],
        [S].[name]                  as [object_schema_name],
        [O].[name]                  as [object_name]
    from [ObjectDependencies] as [D]
        inner join [sys].[objects] as [O]
            on [D].[object_id] = [O].[object_id]
        inner join [sys].[schemas] as [S]
            on [O].[schema_id] = [S].[schema_id]
    order by [dependecy_type], [dependecy_depth], [object_schema_name]
    option (maxrecursion 4096);
    
end;
go
