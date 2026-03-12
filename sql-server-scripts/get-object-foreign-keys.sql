create or alter procedure [#GetObjectForeignKeys](
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

    select
        [PC].[name]                                as [column_name],
        cast(N'References' as nvarchar(20))        as [dependency_type],
        [RO].[type_desc]                           as [target_object_type],
        [RS].[name]                                as [target_object_schema_name],
        [RO].[name]                                as [target_object_name],
        [RC].[name]                                as [target_column_name],
        [FK].[name]                                as [constraint_name],
        [FKC].[constraint_column_id]               as [constraint_column_ordinal]
    from [sys].[foreign_keys] as [FK]
        inner join [sys].[foreign_key_columns] as [FKC]
            on [FK].[object_id] = [FKC].[constraint_object_id]
        inner join [sys].[objects] as [RO]
            on [FK].[referenced_object_id] = [RO].[object_id]
        inner join [sys].[schemas] as [RS]
            on [RO].[schema_id] = [RS].[schema_id]
        inner join [sys].[columns] as [PC]
            on [FKC].[parent_object_id] = [PC].[object_id]
           and [FKC].[parent_column_id] = [PC].[column_id]
        inner join [sys].[columns] as [RC]
            on [FKC].[referenced_object_id] = [RC].[object_id]
           and [FKC].[referenced_column_id] = [RC].[column_id]
    where [FK].[parent_object_id] = @objectId

    union all

    select
        [RC].[name]                                as [column_name],
        cast(N'ReferencedBy' as nvarchar(20))      as [dependency_type],
        [PO].[type_desc]                           as [target_object_type],
        [PS].[name]                                as [target_object_schema_name],
        [PO].[name]                                as [target_object_name],
        [PC].[name]                                as [target_column_name],
        [FK].[name]                                as [constraint_name],
        [FKC].[constraint_column_id]               as [constraint_column_ordinal]
    from [sys].[foreign_keys] as [FK]
        inner join [sys].[foreign_key_columns] as [FKC]
            on [FK].[object_id] = [FKC].[constraint_object_id]
        inner join [sys].[objects] as [PO]
            on [FK].[parent_object_id] = [PO].[object_id]
        inner join [sys].[schemas] as [PS]
            on [PO].[schema_id] = [PS].[schema_id]
        inner join [sys].[columns] as [PC]
            on [FKC].[parent_object_id] = [PC].[object_id]
           and [FKC].[parent_column_id] = [PC].[column_id]
        inner join [sys].[columns] as [RC]
            on [FKC].[referenced_object_id] = [RC].[object_id]
           and [FKC].[referenced_column_id] = [RC].[column_id]
    where [FK].[referenced_object_id] = @objectId

    order by [dependency_type], [constraint_name], [constraint_column_ordinal];
end;
go
