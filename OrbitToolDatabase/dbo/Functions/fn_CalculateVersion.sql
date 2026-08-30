/*
    Function: fn_CalculateVersion
    Description: Calculates the next version string based on the previous version.
    Logic:
    - The version format is "YY.QQ.NN" where:
        - YY = last two digits of the year
        - QQ = quarter code (10, 20, 30, 40)
        - NN = incremental number starting from 01 for each new quarter/year
    - If the previous version is NULL or invalid, it defaults to "YY.QQ.01".
    - If the previous version is from a different year or quarter, it resets NN to 01.
    - If the previous version is from the same year and quarter, it increments NN by 1.
*/
CREATE FUNCTION [dbo].[fn_CalculateVersion] (@PreviousVersion VARCHAR(50))
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @QQ VARCHAR(2), @YearSuffix VARCHAR(2), @NewNN INT, @Result VARCHAR(50);

    -- Calculate current quarter code (10, 20, 30, 40) and 2-digit year
    SET @QQ = CAST(DATEPART(QUARTER, GETDATE()) * 10 AS VARCHAR(2));
    SET @YearSuffix = RIGHT(CAST(YEAR(GETDATE()) AS VARCHAR(4)), 2);

    IF @PreviousVersion IS NULL OR CHARINDEX('.', @PreviousVersion) = 0
    BEGIN
        -- Default initial version: YY.QQ.01
        SET @Result = @YearSuffix + '.' + @QQ + '.01';
    END
    ELSE
    BEGIN
        DECLARE @PrevYear VARCHAR(2), @PrevQQ VARCHAR(2), @PrevNN INT;

        -- Extract components from format "YY.QQ.NN"
        SET @PrevYear = PARSENAME(@PreviousVersion, 3);
        SET @PrevQQ   = PARSENAME(@PreviousVersion, 2);
        SET @PrevNN   = CAST(PARSENAME(@PreviousVersion, 1) AS INT);

        IF @PrevYear <> @YearSuffix OR @PrevQQ <> @QQ
        BEGIN
            -- New year or quarter -> reset NN to 01
            SET @Result = @YearSuffix + '.' + @QQ + '.01';
        END
        ELSE
        BEGIN
            -- Same year and quarter -> increment NN
            SET @NewNN = @PrevNN + 1;
            SET @Result = @YearSuffix + '.' + @QQ + '.' + RIGHT('0' + CAST(@NewNN AS VARCHAR(2)), 2);
        END
    END

    RETURN @Result;
END