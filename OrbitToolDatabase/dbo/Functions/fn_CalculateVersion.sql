CREATE FUNCTION [dbo].[fn_CalculateVersion] (@PreviousVersion VARCHAR(50))
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @Quarter INT, @YearSuffix VARCHAR(2), @NewNN INT, @Result VARCHAR(50);

    -- Calculate current quarter (Jan–Mar = 01, Apr–Jun = 02, Jul–Sep = 03, Oct–Dec = 04)
    SET @Quarter = DATEPART(QUARTER, GETDATE());
    SET @YearSuffix = RIGHT(CONVERT(VARCHAR(4), YEAR(GETDATE())), 2);

    IF @PreviousVersion IS NULL
    BEGIN
        SET @Result = RIGHT('0' + CAST(@Quarter AS VARCHAR(2)), 2) + '.' + @YearSuffix + '.01';
    END
    ELSE
    BEGIN
        DECLARE @PrevQuarter VARCHAR(2), @PrevYear VARCHAR(2), @PrevNN INT;

        SET @PrevQuarter = LEFT(@PreviousVersion, 2);
        SET @PrevYear = SUBSTRING(@PreviousVersion, 4, 2);
        SET @PrevNN = CAST(RIGHT(@PreviousVersion, 2) AS INT);

        IF @PrevQuarter <> RIGHT('0' + CAST(@Quarter AS VARCHAR(2)), 2)
           OR @PrevYear <> @YearSuffix
        BEGIN
            -- New quarter or year → reset NN
            SET @Result = RIGHT('0' + CAST(@Quarter AS VARCHAR(2)), 2) + '.' + @YearSuffix + '.01';
        END
        ELSE
        BEGIN
            -- Same quarter/year → increment NN
            SET @NewNN = @PrevNN + 1;
            SET @Result = @PrevQuarter + '.' + @PrevYear + '.' + RIGHT('0' + CAST(@NewNN AS VARCHAR(2)), 2);
        END
    END

    RETURN @Result;
END
