create or alter procedure [$1:schemaName].[$2:procedureName](
    $3:parameters
)
as
declare
    $4:variables
begin
    set xact_abort, nocount on;
    set transaction isolation level $5:isolationLevel;

    begin transaction;
    begin try

        $0:procedureBody

        commit transaction;
    end try
    begin catch
        if @@trancount > 0
        begin
            rollback transaction;
        end;
        
        throw;
    end catch
end;
go
