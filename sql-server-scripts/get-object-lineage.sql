create or alter procedure [#GetObjectLineage](
    @object nvarchar(max)
)
as
declare
    @objectId int
begin
    set xact_abort, nocount on;

    set @object = trim(@object);

    if object_id(@object) is not null
    begin
        set @objectId = object_id(@object);
    end;
    else if object_name(try_cast(@object as int)) is not null
    begin
        set @objectId = try_cast(@object as int);
    end;
    else
    begin
        raiserror(N'Cannot find object with name or id "%s".', 16, 1, @object);
        return;
    end;

    with
        [AllDependencies] as (
            select distinct
                [D].[referencing_id]                        as [referencing_id],
                [D].[referenced_id]                         as [referenced_id]
            from [sys].[sql_expression_dependencies] as [D]
            where [D].[referenced_id] is not null
        ),
        [Uses] as (
            select
                cast(N'Uses' as nvarchar(20))               as [dependency_type],
                0                                           as [dependency_depth],
                [D].[referenced_id]                         as [object_id]
            from [AllDependencies] as [D]
            where [D].[referencing_id] = @objectId

            union all

            select
                cast(N'UsesIndirectly' as nvarchar(20))     as [dependency_type],
                [U].[dependency_depth] + 1                  as [dependency_depth],
                [D].[referenced_id]                         as [object_id]
            from [AllDependencies] as [D]
                inner join [Uses] as [U]
                    on [D].[referencing_id] = [U].[object_id]
        ),
        [UsedBy] as (
            select
                cast(N'UsedBy' as nvarchar(20))             as [dependency_type],
                0                                           as [dependency_depth],
                [D].[referencing_id]                        as [object_id]
            from [AllDependencies] as [D]
            where [D].[referenced_id] = @objectId

            union all

            select
                cast(N'UsedByIndirectly' as nvarchar(20))   as [dependency_type],
                [U].[dependency_depth] + 1                  as [dependency_depth],
                [D].[referencing_id]                        as [object_id]
            from [AllDependencies] as [D]
                inner join [UsedBy] as [U]
                    on [D].[referenced_id] = [U].[object_id]
        ),
        [ObjectDependencies] as (
            select * from [Uses]
            union all
            select * from [UsedBy]
        )
    select distinct
        [D].[dependency_type]                               as [dependency_type],
        [D].[dependency_depth]                              as [dependency_depth],
        [O].[type_desc]                                     as [object_type],
        [S].[name]                                          as [object_schema_name],
        [O].[name]                                          as [object_name]
    from [ObjectDependencies] as [D]
        inner join [sys].[objects] as [O]
            on [D].[object_id] = [O].[object_id]
        inner join [sys].[schemas] as [S]
            on [O].[schema_id] = [S].[schema_id]
    order by
        [dependency_type],
        [dependency_depth],
        [object_schema_name],
        [object_name]
    option (maxrecursion 4096);
end;
go
