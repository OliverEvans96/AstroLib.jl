# This file is a part of AstroLib.jl. License is MIT "Expat".
# Copyright (C) 2016 Mosè Giordano.

"""
    adstring(ra::Number, dec::Number[, precision::Int=2, truncate::Bool=true])
                                                                  -> ASCIIString
    adstring([ra, dec]) -> ASCIIString
    adstring(dec) -> ASCIIString
    adstring([ra], [dec]) -> AbstractArray{ASCIIString}

### Purpose ###

Returns right ascension and declination as string(s) in sexagesimal format.

### Explanation ###

Takes right ascension and declination expressed in decimal format, converts them
to sexagesimal and return a formatted string.  The precision of right ascension
and declination can be specified.

### Arguments ###

Arguments of this function are:

* `ra`: right ascension in decimal degrees.  It is converted to hours before
  printing.
* `dec`: declination in decimal degrees.

The function can be called in different ways:

* Two numeric arguments: first is `ra`, the second is `dec`.
* One 2-element numeric array: `[ra, dec]`.  A single string is returned.
* One numeric argument: it is assumed only `dec` is provided.
* Two numeric arrays of the same length: `ra` and `dec` arrays.  An array of
  strings is returned.

Optional keywords affecting the output format are always available:

* `precision` (optional integer keyword): specifies the number of digits of
  declination seconds.  The number of digits for righ ascension seconds is
  always assumed to be one more `precision`.  If the function is called with
  only `dec` as input, `precision` default to 1, in any other case defaults to
  0.
* `truncate` (optional boolean keyword): if true, then the last displayed digit
  in the output is truncated in precision rather than rounded.  This option is
  useful if `adstring` is used to form an official IAU name (see
  http://vizier.u-strasbg.fr/Dic/iau-spec.htx) with coordinate specification.

### Output ###

The function returns one string if the function was called with scalar `ra` and
`dec` (or only `dec`) or a 2-element array `[ra, dec]`.  If instead it was
feeded with arrays of `ra` and `dec`, an array of strings will be returned.  The
format of strings can be specified with `precision` and `truncate` keywords, see
above.

### Example ###

```
julia> adstring(30.4, -1.23, truncate=true)
" 02 01 35.9  -01 13 48"

julia> adstring([30.4, -15.63], [-1.23, 48.41], precision=1)
2-element Array{AbstractString,1}:
 " 02 01 36.00  -01 13 48.0"
 "-22 57 28.80  +48 24 36.0"
```
"""
function adstring(ra::Number, dec::Number;
                  precision::Int=0, truncate::Bool=false)
    # Helper function to format seconds part.
    function formatsec(sec::Number, prec::Int64)
        sec = truncate ? trunc(sec, prec) : round(sec, prec)
        # Seconds of right ascension should be always positive (the hours part
        # holds the sign), so we don't need to take the absolute values.
        sec_frac, sec_int = modf(sec)
        # Format the integer part left padding with zeros.
        sec_int_str = lpad(string(trunc(Int64, sec_int)), 2, "0")
        # Unless precision is 0, format the fractional part with the decimal
        # separator "." followed by seconds rounded to the precision required
        # and right padded with zeros.
        sec_frac_str = prec == 0 ? "" :
            rpad(string(".", round(Int64, sec_frac*exp10(prec))), prec + 1, "0")
        return sec_string = string(sec_int_str, sec_frac_str)
    end

    # XXX: IDL implementation takes also real values for "precision" and
    # truncates it.  I think it's better to enforce an integer type and cure
    # only negative values.
    precision = precision < 0 ? 0 : precision
    if isnan(ra)
        # If "ra" is NaN, print only declination.
        dec_deg, dec_min, dec_sec = sixty(dec)
        ra_string = ""
    else
        ra_hr, ra_min, ra_sec, dec_deg, dec_min, dec_sec = radec(ra, dec)
        # Don't print "+" for positive right ascension and leave the first
        # character blank.
        ra_sign = ra >= 0.0 ? ' ' : '-'
        ra_sec_string = formatsec(ra_sec, precision + 1)
        ra_string = @sprintf("%c%02d %02d %s  ", ra_sign, abs(ra_hr),
                             ra_min, ra_sec_string)
    end
    dec_sign = dec >= 0.0 ? '+' : '-'
    dec_sec_string = formatsec(dec_sec, precision)
    dec_string = @sprintf("%c%02d %02d %s", dec_sign, abs(dec_deg),
                          dec_min, dec_sec_string)
    return string(ra_string, dec_string)
end

# When printing only declination, IDL implementation defaults "precision" to 1
# instead of 0.
adstring(dec::Number; precision::Int=1, truncate::Bool=false) =
    adstring(NaN, dec, precision=precision, truncate=truncate)

function adstring{T<:Number}(radec::AbstractArray{T};
                             precision::Int=0, truncate::Bool=false)
    @assert length(radec) == 2 "provide a 2-element [ra, dec] array"
    return adstring(radec[1], radec[2], precision=precision, truncate=truncate)
end

function adstring{R<:Number, D<:Number}(ra::AbstractArray{R},
                                        dec::AbstractArray{D};
                                        precision::Int=0, truncate::Bool=false)

    @assert length(ra) == length(dec) "ra and dec arrays should be of the same length"
    result = similar(ra, AbstractString)
    for i in eachindex(ra)
        result[i] = adstring(ra[i], dec[i],
                             precision=precision, truncate=truncate)
    end
    return result
end