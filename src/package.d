// Written in the D programming language.

/**

IEEE 754-2008 implementation of _decimal floating point data types.
_Decimal values are represented in memory using a coefficient and a 10-base exponent.
Implementation is based on 
$(LINK2 https://en.wikipedia.org/wiki/Binary_Integer_Decimal, binary integer _decimal encoding), supported by Intel.

_Decimal data types use the same semantics as the built-in floating point data type (NaNs, infinities, etc.), 
the main difference being that they use internally a 10 exponent instead of a 2 exponent. 

The current implementation supports three _decimal data types, as specified by IEEE 754-2008 standard. 
The supported types are: $(MYREF decimal32), $(MYREF decimal64) and $(MYREF decimal128), but they can be easily extended
to other bit widths if a underlying unsigned integral type is provided.

_Decimal data types are best used in financial applications because arithmetic operation results are exact. 

$(SCRIPT inhibitQuickIndex = 1;)
$(DIVC quickindex,
 $(BOOKTABLE ,
  $(TR $(TH Category) $(TH Members) )
    $(TR $(TDNW Classics) $(TD
        $(MYREF abs) $(MYREF copysign) 
        $(MYREF fmod) $(MYREF fma) $(MYREF getNaNPayload)  
        $(MYREF modf) $(MYREF NaN) 
        $(MYREF nextDown)  $(MYREF nextUp) $(MYREF remainder) $(MYREF sgn) 
    ))
    $(TR $(TDNW Comparison) $(TD   
        $(MYREF cmp) 
        $(MYREF fmax) $(MYREF fmaxAbs) $(MYREF fmin) $(MYREF fminAbs)
        $(MYREF isEqual) $(MYREF isGreater) $(MYREF isGreaterOrEqual) $(MYREF isGreaterOrUnordered)
        $(MYREF isIdentical)
        $(MYREF isLess) $(MYREF isLessOrEqual) $(MYREF isLessOrUnordered)
        $(MYREF isLessOrGreater) 
        $(MYREF isNotEqual)
        $(MYREF sameQuantum)
        $(MYREF totalOrder) $(MYREF totalOrderAbs)
    ))
    $(TR $(TDNW Conversion) $(TD
        $(MYREF fromDPD) $(MYREF fromMsCurrency) $(MYREF fromMsDecimal) $(MYREF to) $(MYREF toDPD) $(MYREF toExact) 
        $(MYREF toMsCurrency) $(MYREF toMsDecimal) 
    ))
    $(TR $(TDNW Data types) $(TD
        $(MYREF Decimal) $(MYREF decimal32) $(MYREF decimal64)  $(MYREF decimal128) 
        $(MYREF DecimalClass) $(MYREF DecimalControl) $(MYREF ExceptionFlags)  $(MYREF Precision)
        $(MYREF RoundingMode) 
    ))
    $(TR $(TDNW Exceptions) $(TD
        $(MYREF DecimalException) $(MYREF DivisionByZeroException) 
        $(MYREF InexactException) $(MYREF InvalidOperationException)
        $(MYREF OverflowException) $(MYREF UnderflowException)  
    ))
    $(TR $(TDNW Exponentiations & logarithms) $(TD
        $(MYREF cbrt) $(MYREF compound)
        $(MYREF exp) $(MYREF exp10) $(MYREF exp10m1) $(MYREF exp2) $(MYREF exp2m1) $(MYREF expm1) $(MYREF frexp)
        $(MYREF ilogb) $(MYREF ldexp) $(MYREF log) $(MYREF log10) $(MYREF log10p1) $(MYREF log2) $(MYREF log2p1) 
        $(MYREF logp1) $(MYREF nextPow10) $(MYREF pow) $(MYREF root) 
        $(MYREF rsqrt) $(MYREF scalbn) $(MYREF sqrt)  
        $(MYREF truncPow10)
    ))
    $(TR $(TDNW Introspection) $(TD
        $(MYREF decimalClass) 
        $(MYREF isCanonical) $(MYREF isFinite) $(MYREF isInfinity) $(MYREF isNaN) $(MYREF isNormal) 
        $(MYREF isPowerOf10) $(MYREF isSignaling) $(MYREF isSubnormal) $(MYREF isZero) 
        $(MYREF signbit) 
    ))
    $(TR $(TDNW Reduction) $(TD
        $(MYREF dot) $(MYREF poly) $(MYREF scaledProd) $(MYREF scaledProdSum) $(MYREF scaledProdDiff)
        $(MYREF sum) $(MYREF sumAbs) $(MYREF sumSquare) 
    ))
    $(TR $(TDNW Rounding) $(TD
        $(MYREF ceil) $(MYREF floor) $(MYREF lrint) $(MYREF lround) $(MYREF nearbyint) $(MYREF quantize) $(MYREF rint) 
        $(MYREF rndtonl) $(MYREF round) $(MYREF trunc)  
    ))
    $(TR $(TDNW Trigonometry) $(TD
        $(MYREF acos) $(MYREF acosh) $(MYREF asin) $(MYREF asinh) $(MYREF atan) $(MYREF atan2) $(MYREF atan2pi) 
        $(MYREF atanh) $(MYREF atanpi) $(MYREF cos) $(MYREF cosh) $(MYREF cospi)
        $(MYREF hypot) $(MYREF sin) $(MYREF sinh) $(MYREF sinpi) $(MYREF tan) $(MYREF tanh)
    ))
    

 )   
)


Context:

All arithmetic operations are performed using a $(U thread local context). The context is setting various 
environment options:
$(UL
 $(LI $(B precision) - number of digits used. Each _decimal data type has a default precision and all the calculations are
                  performed using this precision. Setting the precision to a custom value will affect
                  any subsequent operation and all the calculations will be performed using the specified 
                  number of digits. See $(MYREF Precision) for details;)
 $(LI $(B rounding)  - rounding method used to adjust operation results. If a result will have more digits than the current 
                  context precision, it will be rounded using the specified method. For available rounding modes,
                  see $(MYREF RoundingMode) for details;)
 $(LI $(B flags)     - error flags. Every _decimal operation may signal an error. The context will gather these errors for 
                  later introspection. See $(MYREF ExceptionFlags) for details;)
 $(LI $(B traps)     - exception traps. Any error flag which is set may trigger a $(MYREF DecimalException) if
                  the corresponding trap is installed. See $(MYREF ExceptionFlags) for details;)
)

Operators:

All floating point operators are implemented. Binary operators accept as right side argument any _decimal, integral or 
floating point type.

Initialization:

Creating _decimal floating point values can be done in several ways:
$(UL
 $(LI by assigning a binary floating point, integral, char, bool, string or character range value:
---
decimal32 d = 123;
decimal64 e = 12.34;
decimal128 f = "24.9";
decimal32 g = 'Y';
decimal32 h = true;
---
)
 $(LI by using one of the available contructors. 
   Suported type are floating point, integrals, chars, bool, strings or character ranges:
---
auto d = decimal32(7500);
auto e = decimal64(52.16);
auto f - decimal128("199.4E-12");
auto g = decimal32('a');
auto h = decimal32(false);
---
)
 $(LI using one of predefined constants:
---
auto d = decimal32.nan;
auto e = decimal64.PI;
auto f - decimal128.infinity;
---
)
)

Error_handling:

Errors occuring in arithmetic operations using _decimal values can be handled in two ways. By default, the thread local 
context will throw exceptions for errors considered severe ($(MYREF InvalidOperationException), 
$(MYREF DivisionByZeroException) or $(MYREF OverflowException)). 
Any other error is considered silent and the context will only 
set corresponding error flags ($(MYREF ExceptionFlags.inexact) or $(MYREF ExceptionFlags.underflow))<br/>
Most of the operations will throw $(MYREF InvalidOperationException) if a signaling NaN is encountered, 
if not stated otherwise in the documentation. This is to avoid usage of unitialized variables 
(_decimal values are always initialized to signaling NaN)
---
//these will throw:
auto a = decimal32() + 12;    //InvalidOperationException
auto b = decimal32.min / 0;   //DivisionByZeroException
auto c = decimal32.max * 2;   //OverflowException

//these will not throw:
auto d = decimal32(123456789);                  //inexact
auto e = decimal32.min_normal / decimal32.max;  //underflow
---

Default behaviour can be altered using $(MYREF DecimalControl) by setting or clearing corresponding traps:
---
DecimalControl.disableExceptions(ExceptionFlags.overflow)
//from now on OverflowException will not be thrown;

DecimalControl.enableExceptions(ExceptionFlags.inexact)
//from now on InexactException will be thrown
---

$(UL
  $(LI Catching exceptions)
  ---
  try 
  {
     auto a = decimal32.min / 0;
  }
  catch (DivisionByZeroException)
  {
     //error occured
  }
  ---
  $(LI Checking for errors)
  ---
  DecimalControl.resetFlags();
  auto a = decimal32.min / 0;
  if (DecimalControl.divisionByZero)
  {
     //error occured
  }
  ---
)

Properties:

The following properties are defined for each _decimal type:

$(BOOKTABLE,
 $(TR $(TH Constant) $(TH Name) $(TH decimal32) $(TH decimal64) $(TH decimal128))
 $(TR $(TD $(D init)) $(TD initial value) $(TD signaling NaN) $(TD signaling NaN) $(TD signaling NaN))
 $(TR $(TD $(D nan)) $(TD Not a Number) $(TD NaN) $(TD NaN) $(TD NaN))
 $(TR $(TD $(D infinity)) $(TD positive infinity) $(TD +∞) $(TD +∞) $(TD +∞))
 $(TR $(TD $(D dig)) $(TD precision) $(TD 7) $(TD 16) $(TD 34))
 $(TR $(TD $(D epsilon)) $(TD smallest increment to the value 1) $(TD 10$(SUPERSCRIPT-6)) $(TD 10$(SUPERSCRIPT-15)) $(TD 10$(SUPERSCRIPT-33)))
 $(TR $(TD $(D mant_dig)) $(TD number of bits in mantissa) $(TD 24) $(TD 54) $(TD 114))
 $(TR $(TD $(D max_10_exp)) $(TD maximum int value such that 10$(SUPERSCRIPT max_10_exp) is representable) $(TD 96) $(TD 384) $(TD 6144))
 $(TR $(TD $(D min_10_exp)) $(TD minimum int value such that 10$(SUPERSCRIPT min_10_exp) is representable and normalized) $(TD -95) $(TD -383) $(TD -6143))
 $(TR $(TD $(D max_2_exp)) $(TD maximum int value such that 2$(SUPERSCRIPT max_2_exp) is representable) $(TD 318) $(TD 1275) $(TD 20409))
 $(TR $(TD $(D min_2_exp)) $(TD minimum int value such that 2$(SUPERSCRIPT min_2_exp) is representable and normalized) $(TD -315) $(TD -1272) $(TD -20406))
 $(TR $(TD $(D max)) $(TD largest representable value that's not infinity) $(TD 9.(9) * 10$(SUPERSCRIPT 96)) $(TD 9.(9) * 10$(SUPERSCRIPT 384)) $(TD 9.(9) * 10$(SUPERSCRIPT 6144)))
 $(TR $(TD $(D min_normal)) $(TD smallest normalized value that's not 0) $(TD 10$(SUPERSCRIPT -95)) $(TD 10$(SUPERSCRIPT -383)) $(TD 10$(SUPERSCRIPT -6143)))
)


Useful_constants:

There are common constants defined for each type. Values below have 34 digits of precision corresponding
to decimal128 data type; for decimal64 and decimal32, they are rounded away from 0 according to their respecive precision.
---
auto a = decimal32.PI;
auto b = decimal64.LN2;
auto c = decimal128.E;
---

$(BOOKTABLE,
 $(TR $(TH Constant) $(TH Formula) $(TH Value))
 $(TR $(TD $(D E)) $(TD e) $(TD 2.7182818284590452353602874713526625))
 $(TR $(TD $(D PI)) $(TD π) $(TD 3.1415926535897932384626433832795029))
 $(TR $(TD $(D PI_2)) $(TD π/2) $(TD 1.5707963267948966192313216916397514))
 $(TR $(TD $(D PI_4)) $(TD π/4) $(TD 0.7853981633974483096156608458198757))
 $(TR $(TD $(D M_1_PI)) $(TD 1/π) $(TD 0.3183098861837906715377675267450287))
 $(TR $(TD $(D M_2_PI)) $(TD 2/π) $(TD 0.6366197723675813430755350534900574))
 $(TR $(TD $(D M_2_SQRTPI)) $(TD 2/√π) $(TD 1.1283791670955125738961589031215452))
 $(TR $(TD $(D SQRT2)) $(TD √2) $(TD 1.4142135623730950488016887242096981))
 $(TR $(TD $(D SQRT1_2)) $(TD √½) $(TD 0.7071067811865475244008443621048490))
 $(TR $(TD $(D LN10)) $(TD log$(SUBSCRIPT e)10) $(TD 2.3025850929940456840179914546843642))
 $(TR $(TD $(D LOG2T)) $(TD log$(SUBSCRIPT 2)10) $(TD 3.3219280948873623478703194294893902))
 $(TR $(TD $(D LOG2E)) $(TD log$(SUBSCRIPT 2)e) $(TD 1.4426950408889634073599246810018921))
 $(TR $(TD $(D LOG2)) $(TD log$(SUBSCRIPT 10)2) $(TD 0.3010299956639811952137388947244930))
 $(TR $(TD $(D LOG10E)) $(TD log$(SUBSCRIPT 10)e) $(TD 0.4342944819032518276511289189166051))
 $(TR $(TD $(D LN2)) $(TD log$(SUBSCRIPT e)2) $(TD 0.6931471805599453094172321214581766))
)



Special_remarks:

$(UL
 $(LI Avoid mixing binary floating point values with decimal values, binary foating point values cannot exactly represent 10-based exponents;)
 $(LI There are many representations for the same number (IEEE calls them cohorts). Comparing bit by bit two _decimal values is error prone;)
 $(LI The comparison operator will return float.nan for an unordered result; There is no operator overloading for unordered comparisons;)
 $(LI Hexadecimal notation allows to define uncanonical coefficients (> 10 $(SUPERSCRIPT precision) - 1). According to IEEE standard, these values are considered equal to 0;)
)

Performance_tips:

$(UL
 $(LI When performing _decimal calculations, avoid binary floating point; conversion for base-2 from/to base-10 is costly;)
 $(LI Avoid custom precisions; rounding is expensive since most of the time will involve a division operation;)
 $(LI Use decimal128 only if you truly need 34 digits of precision. decimal64 and decimal32 arithmetic is much faster;)
 $(LI Avoid traps and check yourself for flags; throwing and catching exceptions is expensive;)
 $(LI Contrary to usual approach, multiplication/division by 10 for _decimal values is faster than multiplication/division by 2;)
)


Copyright: Copyright (c) Răzvan Ștefănescu 2018.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Authors:   Răzvan Ștefănescu
Source:    $(LINK2 https://github.com/rumbu13/decimal/blob/master/src/package.d, _decimal.d)

*/
module decimal;

public import std.traits: isIntegral, isFloatingPoint, isSomeChar, isSomeString;
public import std.format: FormatSpec, FormatException;
public import std.range.primitives: isInputRange, ElementType;

version(Windows)
{
    public import core.sys.windows.wtypes: DECIMAL;
}

private import decimal.integrals;
private import decimal.floats;
private import decimal.ranges;
private import decimal.sinks;

private import std.traits: Unqual, isUnsigned, Unsigned, isSigned;
private import core.checkedint: adds, subs;
private import std.range.primitives: front, popFront, empty;
private import std.math: isNaN, isInfinity, signbit, IeeeFlags, FloatingPointControl;

private
{
    alias fma = decimal.integrals.fma;
}


version(unittest)
{
    import std.typetuple;
    import std.stdio;
    import std.format;
}

/**
_Decimal floating-point computer numbering format that occupies 4, 8 or 16 bytes in computer memory.
*/
struct Decimal(int bits) if (bits == 32 || bits == 64 || bits == 128)
{
private:
    alias D = typeof(this);
    alias U = DataType!D;
    
    U data = MASK_SNAN;

    enum expBits        = bits / 16 + 6;                 //8, 10, 14
    enum trailingBits   = bits - expBits - 1;            //23, 53, 113    
    enum PRECISION      = 9 * bits / 32 - 2;             //7, 16, 34
    enum EMAX           = 3 * (2 ^^ (bits / 16 + 3));    //96, 384, 6144

    enum SHIFT_EXP1     = trailingBits;                  //23, 53, 113
    enum SHIFT_EXP2     = trailingBits - 2;              //21, 51, 111

    enum EXP_BIAS       = EMAX + PRECISION - 2;          //101, 398, 6176
    enum EXP_MIN        = -EXP_BIAS;
    enum EXP_MAX        = EMAX - PRECISION + 1;          //90, 369, 6111

    enum MASK_QNAN      = U(0b01111100U) << (bits - 8);
    enum MASK_SNAN      = U(0b01111110U) << (bits - 8);
    enum MASK_INF       = U(0b01111000U) << (bits - 8);
    enum MASK_SGN       = U(0b10000000U) << (bits - 8);
    enum MASK_EXT       = U(0b01100000U) << (bits - 8);
    enum MASK_EXP1      = ((U(1U) << expBits) - 1U) << SHIFT_EXP1;
    enum MASK_EXP2      = ((U(1U) << expBits) - 1U) << SHIFT_EXP2;
    enum MASK_COE1      = ~(MASK_SGN | MASK_EXP1);
    enum MASK_COE2      = ~(MASK_SGN | MASK_EXP2 | MASK_EXT);
    enum MASK_COEX      = U(1U) << trailingBits;
    enum MASK_ZERO      = U(cast(uint)EXP_BIAS) << SHIFT_EXP1;
    enum MASK_PAYL      = (U(1U) << (trailingBits - 3)) - 1U;
    enum MASK_NONE      = U(0U);

    enum COEF_MAX       = pow10!U[PRECISION] - 1U;
    enum PAYL_MAX       = pow10!U[PRECISION - 1] - 1U;

    enum LOG10_2        = 0.30102999566398119521L;

    @nogc nothrow pure @safe
    this(const U signMask, const U expMask, const U coefMask)
    {
        this.data = signMask | expMask | coefMask;
    }

    @nogc nothrow pure @safe
    this(const U coefficient, const int exponent, const bool isNegative)
    in
    {
        assert (coefficient <= (MASK_COE2 | MASK_COEX));
        assert (exponent >= EXP_MIN && exponent <= EXP_MAX);
    }
    out
    {
        assert ((this.data & MASK_INF) != MASK_INF);
    }
    body
    {
        U expMask = U(cast(uint)(exponent + EXP_BIAS));
        U sgnMask = isNegative ? MASK_SGN : MASK_NONE;

        if (coefficient <= MASK_COE1)
            this.data = sgnMask | (expMask << SHIFT_EXP1) | coefficient;
        else
            this.data = sgnMask | (expMask << SHIFT_EXP2) | (coefficient & MASK_COE2) | MASK_EXT;
    }

    @nogc nothrow pure @safe
    ExceptionFlags pack(const U coefficient, const int exponent, const bool isNegative, bool acceptNonCanonical = false)
    {
        ExceptionFlags flags;
        if (exponent > EXP_MAX)
            flags = ExceptionFlags.overflow;
        else if (exponent < EXP_MIN)
            flags = ExceptionFlags.underflow;
        else if (coefficient > COEF_MAX && !acceptNonCanonical)
            flags = ExceptionFlags.overflow;
        else if (coefficient > (MASK_COE2 | MASK_COEX) && acceptNonCanonical)
            flags = ExceptionFlags.overflow;
        else 
        {
            U expMask = U(cast(uint)(exponent + EXP_BIAS));
            U sgnMask = isNegative ? MASK_SGN : MASK_NONE;

            if (coefficient <= MASK_COE1)
                this.data = sgnMask | (expMask << SHIFT_EXP1) | coefficient;
            else
                this.data = sgnMask | (expMask << SHIFT_EXP2) | (coefficient & MASK_COE2) | MASK_EXT;
            return ExceptionFlags.none;
        }
        bool p = errorPack(isNegative, flags, coefficient);
        assert(p);
        return flags;
    }

    @nogc nothrow pure @safe
    bool errorPack(const bool isNegative, const ExceptionFlags flags, const U payload = U(0U))
    {
        if (flags & ExceptionFlags.invalidOperation)
        {
            data = MASK_QNAN;
            data |= (payload & MASK_PAYL);
            if (isNegative)
                data |= MASK_SGN;
        }
        else if (flags & ExceptionFlags.divisionByZero)
        {
            data = MASK_INF;
            if (isNegative)
                data |= MASK_SGN;
        }
        else if (flags & ExceptionFlags.overflow)
        {
            data = MASK_INF;
            if (isNegative)
                data |= MASK_SGN;
        }
        else if (flags & ExceptionFlags.underflow)
        {
            data = MASK_ZERO;
            if (isNegative)
                data |= MASK_SGN;
        }
        else 
            return false;
        return true;
    }

    @nogc nothrow pure @safe
    ExceptionFlags adjustedPack(const U coefficient, const int exponent, const bool isNegative, 
                                 const int precision, const RoundingMode mode, const ExceptionFlags previousFlags)
    {
        if (!errorPack(isNegative, previousFlags, coefficient))
        {
            Unqual!U cx = coefficient;
            int ex = exponent;
            auto flags = coefficientAdjust(cx, ex, EXP_MIN, EXP_MAX, realPrecision(precision), isNegative, mode) | previousFlags;
            return pack(cx, ex, isNegative, flags, false);
        }
        return previousFlags;
    }


    @nogc nothrow pure @safe
    ExceptionFlags pack(const U coefficient, const int exponent, const bool isNegative, 
                        const ExceptionFlags previousFlags, bool acceptNonCanonical = false)
    {
        if (!errorPack(isNegative, previousFlags, coefficient))
            return previousFlags | pack(coefficient, exponent, isNegative, acceptNonCanonical);
        else
            return previousFlags;
    }

    @nogc nothrow pure @safe
    bool unpack(out U coefficient, out int exponent) const
    out
    {
        assert (exponent >= EXP_MIN && exponent <= EXP_MAX);
        assert (coefficient <= (MASK_COE2 | MASK_COEX));
    }
    body
    {
        uint e;
        bool isNegative = unpackRaw(coefficient, e);
        exponent = cast(int)(e - EXP_BIAS);
        return isNegative;
    }

    @nogc nothrow pure @safe
    bool unpackRaw(out U coefficient, out uint exponent) const
    {
        if ((data & MASK_EXT) == MASK_EXT)
        {
            coefficient = data & MASK_COE2 | MASK_COEX;
            exponent = cast(uint)((data & MASK_EXP2) >>> SHIFT_EXP2);
        }
        else
        {
            coefficient = data & MASK_COE1;
            exponent = cast(uint)((data & MASK_EXP1) >>> SHIFT_EXP1);
        }
        return (data & MASK_SGN) != 0U;
    }

    @nogc nothrow pure @safe
    static int realPrecision(const int precision)
    {
        if (precision <= 0 || precision > PRECISION)
            return PRECISION;
        else
            return precision;
    }

    ExceptionFlags packIntegral(T)(const T value, const int precision, const RoundingMode mode)
    if (isIntegral!T)
    {
        if (!value)
        {
            this.data = MASK_ZERO;
            return ExceptionFlags.none;
        }
        else
        {
            static if (isSigned!T)
            {
                bool isNegative = value < 0;
                static if (is(T: long))
                    ulong coefficient = isNegative ? -value : value;
                else
                    uint coefficient = isNegative ? -value : value;
            }
            else
            {
                enum isNegative = false;
                static if (is(T: ulong))
                    ulong coefficient = value;
                else
                    uint coefficient = value;
            }

            auto p = prec(coefficient);
            int exponent = 0;
            return adjustedPack(cast(U)coefficient, exponent, isNegative, precision, mode, ExceptionFlags.none);
        }
    }

    ExceptionFlags packFloatingPoint(T)(const T value, const int precision, const RoundingMode mode) 
    if (isFloatingPoint!T)
    {
        if (value == 0.0)
        {
            data = MASK_ZERO;
        }

        ExceptionFlags flags;
        bool isnegative, isinf, isnan;
        int e;
        static if (is(Unqual!T == float))
        {
            uint m;
            isnegative = funpack(value, e, m, isinf, isnan);
        }
        else static if (is(Unqual!T == real) && real.sizeof == 10)
        {
            ulong m;
            isnegative = runpack(value, e, m, isinf, isnan);
        }
        else
        {
            ulong m;
            isnegative = dunpack(cast(double)value, e, m, isinf, isnan);
        }

        if (isinf)
        {
            data = D.MASK_INF;
            if (isnegative)
                data |= D.MASK_SGN;
            return ExceptionFlags.none;
        }
        else if (isnan)
        {
            data = D.MASK_QNAN;
            if (isnegative)
                data |= D.MASK_SGN;
            return ExceptionFlags.none;
        }
        else if (m == 0)
        {   
            data = D.MASK_ZERO;
            if (isnegative)
                data |= D.MASK_SGN;
            return ExceptionFlags.none;
        }

        if (exp2to10(m, e))
            flags |= ExceptionFlags.inexact;
        
        static if (is(U == uint))
        {
            static if (is(typeof(m) == ulong))
            {
                flags |= coefficientAdjust(m, e, ulong(uint.max), isnegative, mode);
                U coefficient = cast(U)m;
            }
            else
                alias coefficient = m;
        }
        else static if (is(U == ulong))
        {
            static if (is(typeof(m) == uint))
                U coefficient = m;
            else
                alias coefficient = m;
        }
        else
            U coefficient = U(m);

        return adjustedPack(coefficient, e, isnegative, precision, mode, flags);        
    }

    ExceptionFlags packString(C)(const(C)[] value, const int precision, const RoundingMode mode)
    if (isSomeChar!C)
    {
            U coefficient;
            bool isinf, isnan, issnan, isnegative, wasHex;
            int exponent;
            const(C)[] ss = value;
            auto flags = parseDecimal(ss, coefficient, exponent, isinf, isnan, issnan, isnegative, wasHex);

            if (!ss.empty)
                flags |= ExceptionFlags.invalidOperation;

            if (flags & ExceptionFlags.invalidOperation)
            {
                errorPack(isnegative, flags, coefficient);
                return flags;
            }

            if (issnan)
                data = MASK_SNAN | (coefficient & MASK_PAYL);
            else if (isnan)
                data = MASK_QNAN | (coefficient & MASK_PAYL);
            else if (isinf)
                data = MASK_INF;
            else
            {   
                if (!wasHex)
                    flags = adjustedPack(coefficient, exponent, isnegative, precision, mode, flags);
                else
                    flags |= pack(coefficient, exponent, isnegative, flags, true);
            }

            if (isnegative)
                data |= MASK_SGN;

            return flags;
    }

    ExceptionFlags packRange(R)(ref R range, const int precision, const RoundingMode mode)
    if (isInputRange!R && isSomeChar!(ElementType!R) && !isSomeString!range)
    {
            U coefficient;
            bool isinf, isnan, issnan, isnegative, wasHex;
            int exponent;
            auto flags = parseDecimal(range, coefficient, exponent, isinf, isnan, issnan, isnegative, wasHex);

            if (!ss.empty)
                flags |= ExceptionFlags.invalidOperation;

            if (flags & ExceptionFlags.invalidOperation)
            {
                packErrors(isnegative, flags, coefficient);
                return flags;
            }

            if (issnan)
                data = MASK_SNAN | (coefficient & MASK_PAYL);
            else if (isnan)
                data = MASK_QNAN | (coefficient & MASK_PAYL);
            else if (isinf)
                data = MASK_INF;
            if (flags & ExceptionFlags.underflow)
                data = MASK_ZERO;
            else if (flags & ExceptionFlags.overflow)
                data = MASK_INF;
            else 
            {
                flags |= adjustCoefficient(coefficient, exponent, EXP_MIN, EXP_MAX, COEF_MAX, isnegative, mode);
                flags |= adjustPrecision(coefficient, exponent, EXP_MIN, EXP_MAX, precision, isnegative, mode);
            }
            
            if (flags & ExceptionFlags.underflow)
                data = MASK_ZERO;
            else if (flags & ExceptionFlags.overflow)
                data = MASK_INF;

            if (isnegative)
                data |= MASK_SGN;

            return flags;
    }
     

    enum zero           = D(U(0U), 0, false);
    enum minusZero      = D(U(0U), 0, true);
    enum one            = D(U(1U), 0, false);
    enum two            = D(U(2U), 0, false);
    enum three          = D(U(3U), 0, false);
    enum minusOne       = D(U(1U), 0, true);
    enum minusInfinity  = -infinity;
    enum ten            = D(U(10U), 0, false);
    enum minusTen       = D(U(10U), 0, true);
    enum qnan           = nan;
    enum snan           = D(MASK_NONE, MASK_NONE, MASK_SNAN);
    enum subn           = D(U(1U), EXP_MIN, false);
    enum minusSubn      = D(U(1U), EXP_MIN, true);
    enum min            = D(COEF_MAX, EXP_MAX, true);
    enum half           = D(U(5U), -1, false);
    enum threequarters  = D(U(75U), -2, false);
    enum quarter        = D(U(25U), -2, false);


    enum SQRT3          = fromString!D(s_sqrt3);
    enum M_SQRT3        = fromString!D(s_m_sqrt3);
    enum PI_3           = fromString!D(s_pi_3);
    enum PI_6           = fromString!D(s_pi_6);
    enum _5PI_6         = fromString!D(s_5pi_6);
    enum _3PI_4         = fromString!D(s_3pi_4);
    enum _2PI_3         = fromString!D(s_2pi_3);
    enum SQRT3_2        = fromString!D(s_sqrt3_2);
    enum SQRT2_2        = fromString!D(s_sqrt2_2);
    enum onethird       = fromString!D(s_onethird);
    enum twothirds      = fromString!D(s_twothirds);
    enum _5_6           = fromString!D(s_5_6);
    enum _1_6           = fromString!D(s_1_6);
    enum M_1_2PI        = fromString!D(s_m_1_2pi);
    enum PI2            = fromString!D(s_pi2);
public:

    
    enum dig            = PRECISION;
    enum epsilon        = D(U(1U), -PRECISION + 1, false);
    enum infinity       = D(MASK_NONE, MASK_NONE, MASK_INF);
    enum max            = D(COEF_MAX, EXP_MAX, false);
    enum max_10_exp     = EMAX;
    enum max_exp        = cast(int)(max_10_exp / LOG10_2);
    enum mant_dig       = trailingBits;
    enum min_10_exp     = -(max_10_exp - 1);
    enum min_exp        = cast(int)(min_10_exp / LOG10_2);
    enum min_normal     = D(U(1U), min_10_exp, false);    
    enum nan            = D(MASK_NONE, MASK_NONE, MASK_QNAN);
    

    enum E              = fromString!D(s_e);
    enum PI             = fromString!D(s_pi);
    enum PI_2           = fromString!D(s_pi_2);
    enum PI_4           = fromString!D(s_pi_4);
    enum M_1_PI         = fromString!D(s_m_1_pi);
    enum M_2_PI         = fromString!D(s_m_2_pi);
    enum M_2_SQRTPI     = fromString!D(s_m_2_sqrtpi);
    enum SQRT2          = fromString!D(s_sqrt2);
    enum SQRT1_2        = fromString!D(s_sqrt1_2);
    enum LN10           = fromString!D(s_ln10);
    enum LOG2T          = fromString!D(s_log2t);
    enum LOG2E          = fromString!D(s_log2e);
    enum LOG2           = fromString!D(s_log2);
    enum LOG10E         = fromString!D(s_log10e);
    enum LN2            = fromString!D(s_ln2);

    ///always 10 for _decimal data types
    @IEEECompliant("radix", 25)
    enum radix          = 10;

    /**
    Constructs a Decimal data type using the specified _value
    Params:
        value = any integral, char, bool, floating point, decimal, string or character range _value
    Exceptions: 
        $(BOOKTABLE,
            $(TR $(TH Data type) $(TH Invalid) $(TH Overflow) $(TH Underflow) $(TH Inexact))
            $(TR $(TD integral)  $(TD        ) $(TD         ) $(TD          ) $(TD ✓     ))
            $(TR $(TD char    )  $(TD        ) $(TD         ) $(TD          ) $(TD ✓     ))
            $(TR $(TD float   )  $(TD        ) $(TD ✓      ) $(TD ✓       ) $(TD ✓     ))
            $(TR $(TD bool    )  $(TD        ) $(TD         ) $(TD          ) $(TD        ))
            $(TR $(TD decimal )  $(TD        ) $(TD ✓      ) $(TD ✓       ) $(TD ✓     ))
            $(TR $(TD string  )  $(TD ✓     ) $(TD ✓      ) $(TD ✓       ) $(TD ✓     ))
            $(TR $(TD range   )  $(TD ✓     ) $(TD ✓      ) $(TD ✓       ) $(TD ✓     ))
        )
    Using_integral_values:
        ---
        auto a = decimal32(112);       //represented as 112 x 10^^0;
        auto b = decimal32(123456789); //inexact, represented as 1234568 * x 10^^2
        ---
    Using_floating_point_values:
        ---
        auto a = decimal32(1.23);
        //inexact, represented as 123 x 10^^-2, 
        //because floating point data cannot exactly represent 1.23 
        //in fact 1.23 as float is 1.230000019073486328125
        auto b = decimal64(float.nan); 
        ---
    Using_other_decimal_values:
        ---
        auto a = decimal32(decimal64(10)); 
        auto b = decimal64(a);
        auto c = decimal64(decimal128.nan);
        ---
    Using_strings_or_ranges:
        A _decimal value can be defined based on _decimal, scientific or hexadecimal representation:
        $(UL
            $(LI values are rounded away from zero in case of precision overflow;)
            ---
            auto d = decimal32("2.3456789")
            //internal representation will be 2.345679
            //because decimal32 has a 7-digit precision
            ---
            $(LI the exponent in hexadecimal notation is 10-based;)
            ---
            auto d1 = decimal64("0x00003p+21");
            auto d2 = decimal64("3e+21");
            assert (d1 == d2);
            ---
            $(LI the hexadecimal notation doesn't have any _decimal point, 
                because there is no leading 1 as for binary floating point values;)
            $(LI there is no octal notation, any leading zero before the decimal point is ignored;)
            $(LI digits can be grouped using underscores;)
            $(LI case insensitive special values are accepted: $(B nan, qnan, snan, inf, infinity);)
            $(LI there is no digit count limit for _decimal representation, very large values are rounded and adjusted by 
                increasing the 10-exponent;)
            ---
            auto d1 = decimal32("123_456_789_123_456_789_123_456_789_123"); //30 digits
            //internal representation will be 1.234568 x 10^^30
            ---
            $(LI NaN payloads can be defined betwen optional brackets ([], (), {}, <>). 
            The payload is unsigned and is accepted in decimal or hexadecimal format;)
        )   
            ---
            auto d = decimal32("10");              //integral
            auto e = decimal64("125.43")           //floating point
            auto f = decimal128("123.456E-32");    //scientific
            auto g = decimal32("0xABCDEp+21");     //hexadecimal 0xABCD * 10^^21
            auto h = decimal64("NaN1234");         //NaN with 1234 payload
            auto i = decimal128("sNaN<0xABCD>")    //signaling NaN with a 0xABCD payload
            auto j = decimal32("inf");             //infinity
            ---
    Using_char_or_bool_values:
        These constructors are provided only from convenience, and to 
        offer support for conversion function $(PHOBOS conv, to, to).
        Char values are cast to unsigned int.
        Bool values are converted to 0.0 (false) or 1.0 (true)
        ---
        auto a = decimal32(true); //1.0
        auto b = decimal32('a');  //'a' ascii code (97)

        auto c = to!decimal32(false); //phobos to!(bool, decimal32)
        auto d = to!decimal128('Z');  //phobos to!(char, decimal128)
        ---
    */
    @IEEECompliant("convertFormat", 22)
    @IEEECompliant("convertFromDecimalCharacter", 22)
    @IEEECompliant("convertFromHexCharacter", 22)
    @IEEECompliant("convertFromInt", 21)
    @IEEECompliant("decodeBinary", 23)
    this(T)(auto const ref T value)
    {
        ExceptionFlags flags;

        static if (isIntegral!T)
            flags = packIntegral(value, 
                                 __ctfe ? 0 : DecimalControl.precision, 
                                 __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
        else static if (isSomeChar!T)
            flags = packIntegral(cast(uint)value, 
                                 __ctfe ? 0 : DecimalControl.precision, 
                                 __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
        else static if (isFloatingPoint!T)
            flags = packFloatingPoint(value, 
                                 __ctfe ? 0 : DecimalControl.precision, 
                                 __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
        else static if (isSomeString!T)
            flags = packString(value, 
                                 __ctfe ? 0 : DecimalControl.precision, 
                                 __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
        else static if (isInputRange!T && isSomeChar!(ElementType!T))
            flags = packrange(value, 
                                 __ctfe ? 0 : DecimalControl.precision, 
                                 __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
        else static if (is(T: D))
            this.data = value.data;
        else static if (isDecimal!T)
            flags = decimalToDecimal(value, this, 
                                 __ctfe ? 0 : DecimalControl.precision, 
                                 __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
        else static if (is(T: bool))
            this.data = value ? one.data : zero.data;
        else
            static assert (0, "Cannot convert expression of type '" ~ 
                           Unqual!T.stringof ~ "' to '" ~
                           Unqual!D.stringof ~ "'");
        DecimalControl.raiseFlags(flags);
    }


    /**
    Implementation of assignnment operator. It supports the same semantics as the constructor.
    */
    @IEEECompliant("copy", 23)
    auto ref opAssign(T)(auto const ref T value)
    {
        auto result = Unqual!D(value);
        this.data = result.data;
    }

    /**
    Implementation of cast operator. Supported casts: integral, floating point, _decimal, char, bool
    Exceptions: 
        $(BOOKTABLE,
            $(TR $(TH Data type) $(TH Invalid) $(TH Overflow) $(TH Underflow) $(TH Inexact))
            $(TR $(TD integral)  $(TD      ✓) $(TD ✓      ) $(TD ✓       ) $(TD ✓     ))
            $(TR $(TD char    )  $(TD      ✓) $(TD ✓      ) $(TD ✓       ) $(TD ✓     ))
            $(TR $(TD float   )  $(TD        ) $(TD ✓      ) $(TD ✓       ) $(TD ✓     ))
            $(TR $(TD bool    )  $(TD        ) $(TD         ) $(TD          ) $(TD        ))
            $(TR $(TD decimal )  $(TD        ) $(TD ✓      ) $(TD ✓       ) $(TD ✓     ))
        )
    */
    @IEEECompliant("convertFormat", 22)
    @IEEECompliant("encodeBinary", 23)
    T opCast(T)() const
    {
        ExceptionFlags flags;
        Unqual!T result;
        static if (isUnsigned!T)
            flags = decimalToUnsigned(this, result, mode);
        else static if (isSigned!T)
            flags = decimalToSigned(this, result, mode);
        else static if (is(T: D))
            result = this;
        else static if (isDecimal!T)
            auto flags = decimalToDecimal(this, result, precision, mode);
        else static if (isFloatingPoint!T)
            auto flags = decimalToFloat(this, result, mode);
        else static if (isSomeChar!T)
        {
            uint r;
            auto flags = decimalToUnsigned(this, r, mode);
            result = cast(Unqual!T)r;
        }
        else static if (is(T: bool))
            result = !isZero(this);
        else
            static assert(0, "Cannot cast a value of type '" ~ 
                          Unqual!D.stringof ~ "' to '" ~ 
                          Unqual!T.stringof ~ "'");
        DecimalControl.raiseFlags(flags);
        return result;
    }
    

    /**
    Implementation of +/- unary operators. These operations are silent, no exceptions are thrown
    */
    @safe pure nothrow @nogc
    auto opUnary(string op: "+")() const
    {
        return this;
    }

    ///ditto
    @IEEECompliant("negate", 23)
    @safe pure nothrow @nogc
    auto opUnary(string op: "-")() const
    {
        D result = this;
        result.data ^= MASK_SGN;
        return result;
    }

    /**
    Implementation of ++/-- unary operators.
    Exceptions: 
        $(BOOKTABLE,
            $(TR $(TH Value) $(TH ++/-- ) $(TH Invalid) $(TH Overflow) $(TH Inexact))
            $(TR $(TD NaN  ) $(TD NaN   ) $(TD ✓     ) $(TD         ) $(TD        ))
            $(TR $(TD ±∞   ) $(TD ±∞    ) $(TD        ) $(TD         ) $(TD        ))
            $(TR $(TD any  ) $(TD any   ) $(TD        ) $(TD ✓      ) $(TD ✓     ))
        )
    */
    @safe
    auto ref opUnary(string op: "++")()
    {
        auto flags = decimalInc(this, 1U, 
                                __ctfe ? 0 : DecimalControl.precision, 
                                __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
        DecimalControl.raiseFlags(flags);
        return this;
    }

    ///ditto
    @safe
    auto ref opUnary(string op: "--")()
    {
        auto flags = decimalDec(this, -1, 
                                __ctfe ? 0 : DecimalControl.precision, 
                                __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
        DecimalControl.raiseFlags(flags);
        return this;
    }


    /**
    Implementation of == operator. This operation is silent, no exceptions are thrown.
    Supported types : _decimal, floating point, integral, char    
    */
    @IEEECompliant("compareQuietEqual", 24)
    @IEEECompliant("compareQuietNotEqual", 24)
    bool opEquals(T)(auto const ref T value) const
    {
        static if (isDecimal!T || isIntegral!T || isFloatingPoint!T)
            return decimalEqu(this, value);
        else static if (isSomeChar!T)
            return decimalEqu(this, cast(uint)value);
        else
            static assert (0, "Cannot compare values of type '" ~ 
                Unqual!D.stringof ~ "' and '" ~ 
                Unqual!T.stringof ~ "'");
    }

    /**
    Implementation of comparison operator. 
    Supported types : _decimal, floating point, integral, char   
    $(BOOKTABLE,
            $(TR $(TH this) $(TH Value) $(TH Result)    $(TH Invalid)) 
            $(TR $(TD NaN ) $(TD any  ) $(TD NaN   )    $(TD ✓     ))
            $(TR $(TD any ) $(TD NaN  ) $(TD NaN   )    $(TD ✓     )) 
            $(TR $(TD any ) $(TD any  ) $(TD ±1.0, 0.0) $(TD        )) 
        )
    */
    @IEEECompliant("compareSignalingGreater", 24)
    @IEEECompliant("compareSignalingGreaterEqual", 24)
    @IEEECompliant("compareSignalingGreaterUnordered", 24)
    @IEEECompliant("compareSignalingLess", 24)
    @IEEECompliant("compareSignalingLessEqual", 24)
    @IEEECompliant("compareSignalingLessUnordered", 24)
    @IEEECompliant("compareSignalingNotGreater", 24)
    @IEEECompliant("compareSignalingNotLess", 24)
    float opCmp(T)(auto const ref T value) const
    {
        static if (isDecimal!T || isIntegral!T || isFloatingPoint!T)
        {
            int result = decimalCmp(this, value);
            if (result == -2)
            {
                DecimalControl.raiseFlags(ExceptionFlags.invalidOperation);
                return float.nan;
            }
            else
                return cast(float)(result);
        }
        else static if (isSomeChar!T)
        {
            int result = decimalCmp(this, cast(uint)value);
            if (result == -2)
            {
                DecimalControl.raiseFlags(ExceptionFlags.invalidOperation);
                return float.nan;
            }
            else
                return cast(float)(result);
        }
        else
            static assert (0, "Cannot compare values of type '" ~ 
                           Unqual!D.stringof ~ "' and '" ~ 
                           Unqual!T.stringof ~ "'");
    }

    
    /**
    Implementation of binary and assignment operators (+, -, *, /, %, ^^). 
    Returns:
        the widest _decimal value as result of the operation
    Supported_types:
        _decimal, floating point, integral, char   
    Exceptions:
    $(BOOKTABLE,
        $(TR $(TH Left) $(TH Op) $(TH Right) $(TH Result) $(TH Invalid) $(TH Div0) $(TH Overflow) $(TH Underflow) $(TH Inexact))
        $(TR $(TD NaN) $(TD any) $(TD any) $(TD NaN)      $(TD ✓     ) $(TD     ) $(TD         ) $(TD         )  $(TD        ))
        $(TR $(TD any) $(TD any) $(TD NaN) $(TD NaN)      $(TD ✓     ) $(TD     ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD +∞) $(TD +) $(TD -∞) $(TD NaN)          $(TD ✓     ) $(TD     ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD +∞) $(TD +) $(TD any) $(TD +∞)          $(TD        ) $(TD     ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD any) $(TD +) $(TD +∞) $(TD +∞)          $(TD        ) $(TD     ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD -∞) $(TD +) $(TD +∞) $(TD NaN)          $(TD ✓     ) $(TD     ) $(TD         ) $(TD         )  $(TD        ))
        $(TR $(TD -∞) $(TD +) $(TD any) $(TD -∞)          $(TD        ) $(TD     ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD any) $(TD +) $(TD -∞) $(TD -∞)          $(TD        ) $(TD     ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD any) $(TD +) $(TD any) $(TD any)        $(TD        ) $(TD     ) $(TD ✓      ) $(TD ✓      )  $(TD ✓     )) 
        $(TR $(TD +∞) $(TD -) $(TD +∞) $(TD NaN)          $(TD ✓     ) $(TD     ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD +∞) $(TD -) $(TD any) $(TD +∞)          $(TD        ) $(TD     ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD any) $(TD -) $(TD +∞) $(TD -∞)          $(TD        ) $(TD     ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD -∞) $(TD -) $(TD -∞) $(TD NaN)          $(TD ✓     ) $(TD     ) $(TD         ) $(TD         )  $(TD        ))  
        $(TR $(TD -∞) $(TD -) $(TD any) $(TD -∞)          $(TD        ) $(TD     ) $(TD         ) $(TD         )  $(TD        ))  
        $(TR $(TD any) $(TD -) $(TD -∞) $(TD -∞)          $(TD        ) $(TD     ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD any) $(TD -) $(TD any) $(TD any)        $(TD        ) $(TD     ) $(TD ✓      ) $(TD ✓      )  $(TD ✓     )) 
        $(TR $(TD ±∞) $(TD *) $(TD 0.0) $(TD NaN)         $(TD ✓     ) $(TD     ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD ±∞) $(TD *) $(TD any) $(TD ±∞)          $(TD        ) $(TD     ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD any) $(TD *) $(TD any) $(TD any)        $(TD        ) $(TD     ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD ±∞) $(TD /) $(TD ±∞) $(TD NaN)          $(TD ✓     ) $(TD     ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD 0.0) $(TD /) $(TD 0.0) $(TD NaN)        $(TD ✓     ) $(TD     ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD ±∞) $(TD /) $(TD any) $(TD ±∞)          $(TD        ) $(TD     ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD any) $(TD /) $(TD 0.0) $(TD ±∞)         $(TD        ) $(TD ✓  ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD any) $(TD /) $(TD any) $(TD any)        $(TD        ) $(TD     ) $(TD ✓      ) $(TD ✓      )  $(TD ✓     ))  
        $(TR $(TD ±∞) $(TD %) $(TD any) $(TD NaN)         $(TD ✓     ) $(TD     ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD any) $(TD %) $(TD ±∞) $(TD NaN)         $(TD ✓     ) $(TD     ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD any) $(TD %) $(TD 0.0) $(TD NaN)        $(TD ✓     ) $(TD     ) $(TD         ) $(TD         )  $(TD        )) 
        $(TR $(TD any) $(TD %) $(TD any) $(TD any)        $(TD        ) $(TD     ) $(TD ✓      ) $(TD ✓      )  $(TD ✓     )) 
    )
    */
    @IEEECompliant("addition", 21)
    @IEEECompliant("division", 21)
    @IEEECompliant("multiplication", 21)
    @IEEECompliant("pow", 42)
    @IEEECompliant("pown", 42)
    @IEEECompliant("powr", 42)
    @IEEECompliant("remainder", 25)
    @IEEECompliant("substraction", 21)
    auto opBinary(string op, T)(auto const ref T value) const
    if (op == "+" || op == "-" || op == "*" || op == "/" || op == "%" || op == "^^")
    {
        static if (isDecimal!T)
            CommonDecimal!(D, T) result = this;
        else
            Unqual!D result = this;

        static if (op == "+")
            alias decimalOp = decimalAdd;
        else static if (op == "-")
            alias decimalOp = decimalSub;
        else static if (op == "*")
            alias decimalOp = decimalMul;
        else static if (op == "/")
            alias decimalOp = decimalDiv;
        else static if (op == "%")
            alias decimalOp = decimalMod;
        else static if (op = "^^")
            alias decimalOp = decimalPow;
        else 
            static assert(0);



        static if (isIntegral!T || isFloatingPoint!T || isDecimal!T)
            auto flags = decimalOp(result, value, 
                                   __ctfe ? 0 : DecimalControl.precision, 
                                   __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
        else static if (isSomeChar!T)
            auto flags = decimalOp(result, cast(uint)value, 
                                   __ctfe ? 0 : DecimalControl.precision, 
                                   __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
        else
            static assert (0, "Cannot perform binary operation: '" ~ 
                            Unqual!D.stringof ~ "' " ~ op ~" '" ~ 
                            Unqual!T.stringof ~ "'");

        DecimalControl.raiseFlags(flags);
        return result;
    }

    ///ditto
    auto opBinaryRight(string op, T)(auto const ref T value) const
    if (op == "+" || op == "-" || op == "*" || op == "/" || op == "%" || op == "^^")
    {
        static if (isDecimal!T)
            CommonDecimal!(D, T) result = value;
        else
            Unqual!D result;
        static if (op == "+")
            alias decimalOp = decimalAdd;
        else static if (op == "-")
            alias decimalOp = decimalSub;
        else static if (op == "*")
            alias decimalOp = decimalMul;
        else static if (op == "/")
            alias decimalOp = decimalDiv;
        else static if (op == "%")
            alias decimalOp = decimalMod;
        else static if (op = "^^")
            alias decimalOp = decimalPow;
        else 
            static assert(0);

        static if (isDecimal!T)
        {
            
            auto flags = decimalOp(result, this, 
                                   __ctfe ? 0 : DecimalControl.precision, 
                                   __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
        }
        else static if (isIntegral!T || isFloatingPoint!T)
            auto flags = decimalOp(value, this, result,
                                   __ctfe ? 0 : DecimalControl.precision, 
                                   __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
        else static if (isSomeChar!T)
            auto flags = decimalOp(cast(uint)value, this, result,
                                   __ctfe ? 0 : DecimalControl.precision, 
                                   __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
        else
            static assert (0, "Cannot perform binary operation: '" ~ 
                            Unqual!T.stringof ~ "' " ~ op ~" '" ~ 
                            Unqual!D.stringof ~ "'");

        DecimalControl.raiseFlags(flags);
        return result;
    }

    ///ditto
    auto opOpAssign(string op, T)(auto const ref T value)
    if (op == "+" || op == "-" || op == "*" || op == "/" || op == "%" || op == "^^")
    {
        static if (isDecimal!T)
            CommonDecimal!(D, T) result = this;
        else
            Unqual!D result = this;

        static if (op == "+")
            alias decimalOp = decimalAdd;
        else static if (op == "-")
            alias decimalOp = decimalSub;
        else static if (op == "*")
            alias decimalOp = decimalMul;
        else static if (op == "/")
            alias decimalOp = decimalDiv;
        else static if (op == "%")
            alias decimalOp = decimalMod;
        else static if (op = "^^")
            alias decimalOp = decimalPow;
        else 
            static assert(0);



        static if (isIntegral!T || isFloatingPoint!T || isDecimal!T)
            auto flags = decimalOp(this, value, 
                                   __ctfe ? 0 : DecimalControl.precision, 
                                   __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
        else static if (isSomeChar!T)
            auto flags = decimalOp(this, cast(uint)value, 
                                   __ctfe ? 0 : DecimalControl.precision, 
                                   __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
        else
            static assert (0, "Cannot perform assignment operation: '" ~ 
                            Unqual!D.stringof ~ "' " ~ op ~"= '" ~ 
                            Unqual!T.stringof ~ "'");

        DecimalControl.raiseFlags(flags);
        return result;
    }
    
   
   
    /**
    Converts current value to string, passing it to the given sink using
    the specified format.
    Params:
      sink = a delegate used to sink character arrays;
      fmt  = a format specification;
    Notes:
      This function is not intended to be used directly, it is used by the format, output or conversion
      family of functions from Phobos. All standard format options are supported, except digit grouping. 
    Supported_formats:
      $(UL
        $(LI $(B f, F) - floating point notation)
        $(LI $(B e, E) - scientific notation)
        $(LI $(B a, A) - hexadecimal floating point notation)
        $(LI $(B g, G) - shortest representation between floating point and scientific notation)
        $(LI $(B s, S) - same as $(B g, G))
      )
    Throws:
      $(PHOBOS format, FormatException, FormatException) if the format specifier is not supported
    See_Also:
       $(PHOBOS format, FormatSpec, FormatSpec)
       $(PHOBOS format, format, format)
       $(PHOBOS conv, to, to)
       $(PHOBOS stdio, writef, writef)
       $(PHOBOS stdio, writefln, writefln)
    */
    @IEEECompliant("convertToDecimalCharacter", 22)
    @IEEECompliant("convertToHexCharacter", 22)
    void toString(C)(scope void delegate(const(C)[]) sink, FormatSpec!C fmt) const
    if (isSomeChar!C)
    {
        if (__ctfe)
            sinkDecimal(fmt, sink, this, RoundingMode.tiesToAway);
        else
            sinkDecimal(fmt, sink, this, DecimalControl.rounding);
    }

    ///ditto
    @IEEECompliant("convertToDecimalCharacter", 22)
    void toString(C)(scope void delegate(const(C)[]) sink) const
    if (isSomeChar!C)
    {
        sinkDecimal(FormatSpec!C("%g"), sink, this, __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
    }

    ///Converts current value to string in floating point or scientific notation,
    ///which one is shorter.
    @IEEECompliant("convertToDecimalCharacter", 22)
    string toString() const
    {
        return decimalToString!char(this, __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
    }

    ///Converts current value to string according to the 
    ///format specification
    @IEEECompliant("convertToDecimalCharacter", 22)
    @IEEECompliant("convertToHexCharacter", 22)
    string toString(C)(FormatSpec!C fmt) const
    {
        return decimalToString!C(fmt, this, __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
    }

    ///ditto
    @IEEECompliant("convertToDecimalCharacter", 22)
    @IEEECompliant("convertToHexCharacter", 22)
    string toString(C)(const(C)[] fmt) const
    {
        FormatSpec!C spec = singleSpec(fmt);
        return decimalToString!C(spec, this, __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
    }

    /**
    Returns a unique hash of the _decimal value suitable for use in a hash table.
    Notes:
       This function is not intended for direct use, it's provided as support for associative arrays.
    */
    @safe pure nothrow @nogc
    size_t toHash()
    {
        static if (bits == 32)
            return data;
        else static if (bits == 64)
        {
            static if (size_t.sizeof == uint.sizeof)
                return cast(uint)data ^ cast(uint)(data >>> 32);
            else
                return data;
        }
        else
        {
            static if (size_t.sizeof == uint.sizeof)
                return cast(uint)data.hi ^ cast(uint)(data.hi >>> 32) ^
                       cast(uint)data.lo ^ cast(uint)(data.lo >>> 32);
            else
                return data.hi ^ data.lo;
        }
    }
}

///Shorthand notations for $(MYREF Decimal) types
alias decimal32 = Decimal!32;
///ditto
alias decimal64 = Decimal!64;
///ditto
alias decimal128 = Decimal!128;


///Returns true if all specified types are _decimal types.
template isDecimal(D...)
{
    static if (D.length == 0)
        enum isDecimal = false;
    static if (D.length == 1)
        enum isDecimal = is(D[0] == decimal32) || is(D[0] == decimal64) || is(D[0] == decimal128);
    else
        enum isDecimal = isDecimal!(D[0]) && isDecimal!(D[1 .. $]);
}

///
unittest
{
    static assert(isDecimal!decimal32);
    static assert(isDecimal!(decimal32, decimal64));
    static assert(!isDecimal!int);
    static assert(!isDecimal!(decimal128, byte));
}

///Returns the most wide _decimal type among the specified types
template CommonDecimal(T...) if (isDecimal!T)
{
    static if (T.length == 1)
        alias CommonDecimal = T[0];
    else static if (is(T[0] == decimal128) || is(T[1] == decimal128))
        alias CommonDecimal = decimal128;
    else static if (T.length == 2)
    {
        static if (is(T[0] == decimal32))
            alias CommonDecimal = T[1];
        else static if (is(T[1] == decimal32))
            alias CommonDecimal = T[0];
        else static if (is(T[0] == decimal64) && is(T[1] == decimal128))
            alias CommonDecimal = decimal128;
        else static if (is(T[1] == decimal64) && is(T[0] == decimal128))
            alias CommonDecimal = decimal128;
        else static if (is(T[1] == T[0]))
            alias CommonDecimal = T[0];
        else
            static assert(false, "Never happen");
    }
    else
        alias CommonDecimal = CommonDecimal!(CommonDecimal!(T[0 .. 1], CommonDecimal!(T[2 .. $])));
}

///
unittest
{
    static assert(is(CommonDecimal!(decimal32, decimal64) == decimal64));
    static assert(is(CommonDecimal!(decimal32, decimal128) == decimal128));
    static assert(is(CommonDecimal!(decimal64, decimal128) == decimal128));
}


///Root object for all _decimal exceptions
abstract class DecimalException : Exception
{
    mixin ExceptionConstructors;
}

///Thrown if any operand of a _decimal operation is not a number or si not finite
class InvalidOperationException : DecimalException
{
	mixin ExceptionConstructors;
}

///Thrown if the denominator of a _decimal division operation is zero. 
class DivisionByZeroException : DecimalException
{
	mixin ExceptionConstructors;
}

///Thrown if the result of a _decimal operation exceeds the largest finite number of the destination format. 
class OverflowException : DecimalException
{
	mixin ExceptionConstructors;
}

///Thrown if the result of a _decimal operation is smaller the smallest finite number of the destination format. 
class UnderflowException : DecimalException
{
	mixin ExceptionConstructors;
}

///Thrown if the result of a _decimal operation was rounded to fit in the destination format. 
class InexactException : DecimalException
{
	mixin ExceptionConstructors;
}

/**
These flags indicate that an error has occurred. They indicate that a 0, NaN or an infinity value has been generated, 
that a result is inexact, or that a signalling NaN has been encountered. 
If the corresponding traps are set using $(MYREF DecimalControl), 
an exception will be thrown after setting these error flags.

By default the context will have all error flags lowered and exceptions are thrown only for severe errors.
*/
enum ExceptionFlags : uint
{
    ///no error
    none             = 0U,
    ///$(MYREF InvalidOperationException) is thrown if trap is set
	invalidOperation = 1U << 0,
    ///$(MYREF DivisionByZeroException) is thrown if trap is set
	divisionByZero   = 1U << 1,
    ///$(MYREF OverflowException) is thrown if trap is set
	overflow         = 1U << 2,
    ///$(MYREF UnderflowException) is thrown if trap is set
	underflow        = 1U << 3,
    ///$(MYREF InexactException) is thrown if trap is set
	inexact          = 1U << 4,
    ///group of errors considered severe: invalidOperation, divisionByZero, overflow
	severe           = invalidOperation | divisionByZero | overflow,
    ///all errors
	all              = severe | underflow | inexact
}

/**
* Rounding modes. To better understand how rounding is performed, consult the table below. 
*
* $(BOOKTABLE,
*  $(TR $(TH Value) $(TH tiesToEven) $(TH tiesToAway) $(TH towardPositive) $(TH towardNegative) $(TH towardZero)) 
*  $(TR $(TD +1.3)  $(TD +1)         $(TD +1)         $(TD +2)             $(TD +1)             $(TD +1))
*  $(TR $(TD +1.5)  $(TD +2)         $(TD +2)         $(TD +2)             $(TD +1)             $(TD +1))
*  $(TR $(TD +1.8)  $(TD +2)         $(TD +2)         $(TD +2)             $(TD +1)             $(TD +1))
*  $(TR $(TD -1.3)  $(TD -1)         $(TD -1)         $(TD -1)             $(TD -2)             $(TD -1)) 
*  $(TR $(TD -1.5)  $(TD -2)         $(TD -2)         $(TD -1)             $(TD -2)             $(TD -1)) 
*  $(TR $(TD -1.8)  $(TD -2)         $(TD -2)         $(TD -1)             $(TD -2)             $(TD -1)) 
*  $(TR $(TD +2.3)  $(TD +2)         $(TD +2)         $(TD +3)             $(TD +2)             $(TD +2)) 
*  $(TR $(TD +2.5)  $(TD +2)         $(TD +3)         $(TD +3)             $(TD +2)             $(TD +2)) 
*  $(TR $(TD +2.8)  $(TD +3)         $(TD +3)         $(TD +3)             $(TD +2)             $(TD +2)) 
*  $(TR $(TD -2.3)  $(TD -2)         $(TD -2)         $(TD -2)             $(TD -3)             $(TD -2)) 
*  $(TR $(TD -2.5)  $(TD -2)         $(TD -3)         $(TD -2)             $(TD -3)             $(TD -2)) 
*  $(TR $(TD -2.8)  $(TD -3)         $(TD -3)         $(TD -2)             $(TD -3)             $(TD -2)) 
* )  
*/
enum RoundingMode
{
    ///rounded away from zero; halfs are rounded to the nearest even number
	tiesToEven,
    ///rounded away from zero
	tiesToAway,
    ///truncated toward positive infinity
	towardPositive,
    ///truncated toward negative infinity
	towardNegative,
    ///truncated toward zero
	towardZero,

    implicit = tiesToEven,
}

/**
_Precision used to round _decimal operation results. Every result will be adjusted
to fit the specified precision. Use $(MYREF DecimalControl) to query or set the 
context precision
*/
alias Precision = uint;
///ditto
enum : Precision
{
    ///use the default precision of the current type 
    ///(7 digits for decimal32, 16 digits for decimal64 or 34 digits for decimal128)
	precisionDefault = 0,
    ///use 32 bits precision (7 digits)
	precision32 = Decimal!32.PRECISION,
    ///use 64 bits precision (16 digits)
	precision64 = Decimal!64.PRECISION,
    ////use 128 bits precision (34 digits)
    precision128 = Decimal!128.PRECISION,
}

/**
    Container for _decimal context control, provides methods to alter exception handling,
    manually edit error flags, adjust arithmetic precision and rounding mode
*/
struct DecimalControl
{
private:
	static ExceptionFlags flags;
	static ExceptionFlags traps;

    @safe
    static void checkFlags(const ExceptionFlags group, const ExceptionFlags traps)
    {
        if ((group & ExceptionFlags.invalidOperation) && (traps & ExceptionFlags.invalidOperation))
            throw new InvalidOperationException("Invalid operation");
        if ((group & ExceptionFlags.divisionByZero) && (traps & ExceptionFlags.divisionByZero))
            throw new DivisionByZeroException("Division by zero");
        if ((group & ExceptionFlags.overflow) && (traps & ExceptionFlags.overflow))
            throw new OverflowException("Overflow");
        if ((group & ExceptionFlags.underflow) && (traps & ExceptionFlags.underflow))
            throw new UnderflowException("Underflow");
        if ((group & ExceptionFlags.inexact) && (traps & ExceptionFlags.inexact))
            throw new InexactException("Inexact");
    }

public:

    /**
    Gets or sets the rounding mode used when the result of an operation exceeds the _decimal precision.
    See $(MYREF RoundingMode) for details.
    ---
    DecimalControl.rounding = RoundingMode.tiesToEven;
    decimal32 d1 = 123456789;
    assert(d1 == 123456800);

    DecimalControl.rounding = RoundingMode.towardNegative;
    decimal32 d2 = 123456789;
    assert(d2 == 123456700);
    ---
    */
    @IEEECompliant("defaultModes", 46)
    @IEEECompliant("getDecimalRoundingDirection", 46)
    @IEEECompliant("restoreModes", 46)
    @IEEECompliant("saveModes", 46)
    @IEEECompliant("setDecimalRoundingDirection", 46)
    static RoundingMode rounding;

    /**
    Gets or sets the precision applied to peration results.
    See $(MYREF Precision) for details.
    ---
    DecimalControl.precision = precisionDefault;
    decimal32 d1 = 12345;
    assert(d1 == 12345);
    
    DecimalControl.precision = 4;
    decimal32 d2 = 12345;
    assert(d2 == 12350);
    ---
    */
    static Precision precision;

    /**
    Sets specified error flags. Multiple errors may be ORed together.
    ---
    DecimalControl.raiseFlags(ExceptionFlags.overflow | ExceptionFlags.underflow);
    assert (DecimalControl.overflow);
    assert (DecimalControl.underflow);
    ---
	*/
    @IEEECompliant("raiseFlags", 26)
	@safe
	static void raiseFlags(const ExceptionFlags group)
	{
        if (__ctfe)
            checkFlags(group, ExceptionFlags.severe);
        else
        {
            ExceptionFlags newFlags = flags ^ (group & ExceptionFlags.all);
            flags |= group & ExceptionFlags.all;
		    checkFlags(newFlags, traps);
        }
	}

    /**
    Unsets specified error flags. Multiple errors may be ORed together.
    ---
    DecimalControl.resetFlags(ExceptionFlags.inexact);
    assert(!DecimalControl.inexact);
    ---
	*/
    @IEEECompliant("lowerFlags", 26)
    @nogc @safe nothrow
	static void resetFlags(const ExceptionFlags group)
	{
		flags &= ~(group & ExceptionFlags.all);
	}

    ///ditto
    @IEEECompliant("lowerFlags", 26)
    @nogc @safe nothrow
	static void resetFlags()
	{
		flags = ExceptionFlags.none;
	}

    /**
    Enables specified error flags (group) without throwing corresponding exceptions.
    ---
    DecimalControl.restoreFlags(ExceptionFlags.underflow | ExceptionsFlags.inexact);
    assert (DecimalControl.testFlags(ExceptionFlags.underflow | ExceptionFlags.inexact));
    ---
	*/
    @IEEECompliant("restoreFlags", 26)
	@nogc @safe nothrow
	static void restoreFlags(const ExceptionFlags group)
	{
		flags |= group & ExceptionFlags.all;
	}

    /**
    Checks if the specified error flags are set. Multiple exceptions may be ORed together.
    ---
    DecimalControl.raiseFlags(ExceptionFlags.overflow | ExceptionFlags.underflow | ExceptionFlags.inexact);
    assert (DecimalControl.hasFlags(ExceptionFlags.overflow | ExceptionFlags.inexact));
    ---
	*/
    @IEEECompliant("testFlags", 26)
    @IEEECompliant("testSavedFlags", 26)
	@nogc @safe nothrow
	static bool hasFlags(const ExceptionFlags group)
	{
		return (flags & (group & ExceptionFlags.all)) != 0;
	}


     /**
    Returns the current set flags.
    ---
    DecimalControl.restoreFlags(ExceptionFlags.inexact);
    assert (DecimalControl.saveFlags() & ExceptionFlags.inexact);
    ---
	*/
    @IEEECompliant("saveAllFlags", 26)
	@nogc @safe nothrow
	static ExceptionFlags saveFlags()
	{
		return flags;
	}

    /**
    Disables specified exceptions. Multiple exceptions may be ORed together.
    ---
    DecimalControl.disableExceptions(ExceptionFlags.overflow);
    auto d = decimal64.max * decimal64.max;
    assert (DecimalControl.overflow);
    assert (isInfinity(d));
    ---
	*/
	@nogc @safe nothrow
	static void disableExceptions(const ExceptionFlags group)
	{
		traps &= ~(group & ExceptionFlags.all);
	}

    ///ditto
    @nogc @safe nothrow
	static void disableExceptions()
	{
		traps = ExceptionFlags.none;
	}

    

    /**
    Enables specified exceptions. Multiple exceptions may be ORed together.
    ---
    DecimalControl.enableExceptions(ExceptionFlags.overflow);
    try
    {
        auto d = decimal64.max * 2;
    }
    catch (OverflowException)
    {
        writeln("Overflow error")
    }
    ---
	*/
	@nogc @safe nothrow
	static void enableExceptions(const ExceptionFlags group)
	{
		traps |= group & ExceptionFlags.all;
	}  

    /**
    Extracts current enabled exceptions.
    ---
    auto saved = DecimalControl.enabledExceptions;
    DecimalControl.disableExceptions(ExceptionFlags.all);
    DecimalControl.enableExceptions(saved);
    ---
	*/
	@nogc @safe nothrow
	static @property ExceptionFlags enabledExceptions()
	{
		return traps;
	}

    /**
    IEEE _decimal context errors. By default, no error is set.
    ---
    DecimalControl.disableExceptions(ExceptionFlags.all);
    decimal32 uninitialized;
    decimal64 d = decimal64.max * 2;
    decimal32 e = uninitialized + 5.0;
    assert(DecimalControl.overflow);
    assert(DecimalControl.invalidOperation);
    ---
    */
	@nogc @safe nothrow
	static @property bool invalidOperation()
	{
		return (flags & ExceptionFlags.invalidOperation) != 0;
	}

    ///ditto
	@nogc @safe nothrow
	static @property bool divisionByZero()
	{
		return (flags & ExceptionFlags.divisionByZero) != 0;
	}

    ///ditto
	@nogc @safe nothrow
	static @property bool overflow()
	{
		return (flags & ExceptionFlags.overflow) != 0;
	}

    ///ditto
	@nogc @safe nothrow
	static @property bool underflow()
	{
		return (flags & ExceptionFlags.underflow) != 0;
	}

    ///ditto
	@nogc @safe nothrow
	static @property bool inexact()
	{
		return (flags & ExceptionFlags.inexact) != 0;
	}

    ///true if this programming environment conforms to IEEE 754-1985
    @IEEECompliant("is754version1985", 24)
    enum is754version1985 = true;

    ///true if this programming environment conforms to IEEE 754-2008
    @IEEECompliant("is754version2008", 24)
    enum is754version2008 = true;
}

/**
Calculates |x|.
This operation is silent, no error flags are set and no exceptions are thrown.
*/
@IEEECompliant("abs", 23)
D abs(D)(auto const ref D x)
if (isDecimal!D)
{
    D result = x;
    result.data &= ~D.MASK_SGN;
    return result;
}

///
unittest
{
    assert(abs(-decimal32.max) == decimal32.max);
    assert(abs(decimal64.infinity) == decimal64.infinity);
}
/**
Calculates the arc cosine of x, returning a value ranging from 0 to π.
Exceptions:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN or |x| > 1.0))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH acos(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD -1.0) $(TD π))
    $(TR $(TD +1.0) $(TD +0.0))
    $(TR $(TD < -1.0) $(TD NaN))
    $(TR $(TD > +1.0) $(TD NaN))
)
*/
@IEEECompliant("acos", 43)
D acos(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalAcos(result, 
                             __ctfe ? D.PRECISION : DecimalControl.precision, 
                             __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= (ExceptionFlags.inexact | ExceptionFlags.invalidOperation);
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 x = 0;
    assert(acos(x) == decimal32.PI_2);
}

unittest
{
    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert (acos(-T.one) == T.PI);
        assert (acos(T.one) == 0);
        assert (acos(T.zero) == T.PI_2);
        assert (isNaN(acos(T.nan)));
    }
}

/**
Calculates the inverse hyperbolic cosine of x
Exceptions:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN or x < 1.0))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH acosh(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD +1.0) $(TD +0.0))
    $(TR $(TD +∞) $(TD +∞))
    $(TR $(TD < 1.0) $(TD NaN))
)
*/
@IEEECompliant("acosh", 43)
D acosh(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalAcosh(result, 
                             __ctfe ? D.PRECISION : DecimalControl.precision, 
                             __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= (ExceptionFlags.inexact | ExceptionFlags.invalidOperation);
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 x = 1;
    assert (acosh(x) == 0);
}

unittest
{
    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert (acosh(T.one) == T.zero);
        assert (acosh(T.infinity) == T.infinity);
        assert (isNaN(acosh(T.nan)));
    }
}

/**
Calculates the arc sine of x, returning a value ranging from -π/2 to +π/2.
Exceptions:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN or |x| > 1.0))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH asin(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD -1.0) $(TD -π/2))
    $(TR $(TD +1.0) $(TD +π/2))
    $(TR $(TD < -1.0) $(TD NaN))
    $(TR $(TD > +1.0) $(TD NaN))
)
*/
@IEEECompliant("asin", 43)
D asin(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalAsin(result, 
                              __ctfe ? D.PRECISION : DecimalControl.precision, 
                              __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= (ExceptionFlags.inexact | ExceptionFlags.invalidOperation);
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 x = 1;
    assert(asin(x) == decimal32.PI_2);
    assert(asin(-x) == -decimal32.PI_2);
}

unittest
{
    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert (asin(-T.one) == -T.PI_2);
        assert (asin(T.zero) == 0);
        assert (asin(T.one) == T.PI_2);
        assert (isNaN(asin(T.nan)));
    }
}


/**
Calculates the inverse hyperbolic sine of x
Exceptions:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD the result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH asinh(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD ±0.0))
    $(TR $(TD ±∞) $(TD ±∞))
)
*/
@IEEECompliant("asinh", 43)
D asinh(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalAsinh(result, 
                             __ctfe ? D.PRECISION : DecimalControl.precision, 
                             __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= (ExceptionFlags.inexact | ExceptionFlags.invalidOperation | ExceptionFlags.underflow);
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 x = 0;
    assert (asinh(x) == 0);
}

unittest
{
    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert (asinh(T.zero) == T.zero);
        assert (asinh(T.infinity) == T.infinity);
        assert (isNaN(asinh(T.nan)));
    }
}



/**
Calculates the arc tangent of x, returning a value ranging from -π/2 to π/2.
Exceptions:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD the result is too small to be represented))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH atan(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD ±0.0))
    $(TR $(TD ±∞) $(TD ±π/2))
)
*/
@IEEECompliant("atan", 43)
D atan(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalAtan(result, 
                             __ctfe ? D.PRECISION : DecimalControl.precision, 
                             __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= ExceptionFlags.invalidOperation | ExceptionFlags.underflow | ExceptionFlags.inexact;
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 radians = 1;
    assert(atan(radians) == decimal32.PI_4);
}


unittest
{
    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert (isIdentical(atan(T.zero), T.zero));
        assert (isIdentical(atan(-T.zero), -T.zero));
        assert (isIdentical(atan(T.infinity), T.PI_2));
        assert (isIdentical(atan(-T.infinity), -T.PI_2));
        assert (isNaN(atan(T.nan)));
    }
}

/**
Calculates the arc tangent of y / x, returning a value ranging from -π to π.
Exceptions:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x or y is signaling NaN))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD the result is too small to be represented))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH y) $(TH x) $(TH atan2(y, x)))
    $(TR $(TD NaN) $(TD any) $(TD NaN))
    $(TR $(TD any) $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD -0.0) $(TD ±π))
    $(TR $(TD ±0.0) $(TD +0.0) $(TD ±0.0))
    $(TR $(TD ±0.0) $(TD <0.0) $(TD ±π))
    $(TR $(TD ±0.0) $(TD >0.0) $(TD ±0.0))
    $(TR $(TD ±∞) $(TD -∞) $(TD ±3π/4))
    $(TR $(TD ±∞) $(TD +∞) $(TD ±π/4))
    $(TR $(TD ±∞) $(TD any) $(TD ±π/2))
    $(TR $(TD any) $(TD -∞) $(TD ±π))
    $(TR $(TD any) $(TD +∞) $(TD ±0.0))
)
*/
@IEEECompliant("atan2", 43)
auto atan2(D1, D2)(auto const ref D1 y, auto const ref D2 x)
if (isDecimal!(D1, D2))
{
    alias D = CommonDecimal!(D1, D2);
    D result;
    auto flags = decimalAtan2(y, x, result, 
                             __ctfe ? D.PRECISION : DecimalControl.precision, 
                             __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= ExceptionFlags.invalidOperation | ExceptionFlags.underflow | ExceptionFlags.inexact;
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 y = 10;
    decimal32 x = 0;
    assert (atan2(y, x) == decimal32.PI_2);
}

unittest
{

    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert (isNaN(atan2(T.nan, T.zero)));
        assert (isNaN(atan2(T.one, T.nan)));
        assert (atan2(T.zero, -T.zero) == T.PI); 
        assert (atan2(-T.zero, -T.zero) == -T.PI); 
        assert (atan2(T.zero, T.zero) == T.zero);
        assert (atan2(-T.zero, T.zero) == -T.zero); 
        assert (atan2(T.zero, -T.one) == T.PI);
        assert (atan2(-T.zero, -T.one) == -T.PI);
        assert (atan2(T.zero, T.one) == T.zero);
        assert (atan2(-T.zero, T.one) == -T.zero);
        assert (atan2(-T.one, T.zero) == -T.PI_2);
        assert (atan2(T.one, T.zero) == T.PI_2);
        assert (atan2(T.one, -T.infinity) == T.PI);
        assert (atan2(-T.one, -T.infinity) == -T.PI);
        assert (atan2(T.one, T.infinity) == T.zero);
        assert (atan2(-T.one, T.infinity) == -T.zero);
        assert (atan2(-T.infinity, T.one) == -T.PI_2);
        assert (atan2(T.infinity, T.one) == T.PI_2);
        assert (atan2(-T.infinity, -T.infinity) == -T._3PI_4);
        assert (atan2(T.infinity, -T.infinity) == T._3PI_4);
        assert (atan2(-T.infinity, T.infinity) == -T.PI_4);
        assert (atan2(T.infinity, T.infinity) == T.PI_4);
    }
}

/**
Calculates the arc tangent of y / x divided by π, returning a value ranging from -1 to 1.
Exceptions:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x or y is signaling NaN))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD the result is too small to be represented))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH y) $(TH x) $(TH atan2pi(y, x)))
    $(TR $(TD NaN) $(TD any) $(TD NaN))
    $(TR $(TD any) $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD -0.0) $(TD ±1.0))
    $(TR $(TD ±0.0) $(TD +0.0) $(TD ±0.0))
    $(TR $(TD ±0.0) $(TD <0.0) $(TD ±1.0))
    $(TR $(TD ±0.0) $(TD >0.0) $(TD ±0.0))
    $(TR $(TD ±∞) $(TD -∞) $(TD ±3/4))
    $(TR $(TD ±∞) $(TD +∞) $(TD ±1/4))
    $(TR $(TD ±∞) $(TD any) $(TD ±1/2))
    $(TR $(TD any) $(TD -∞) $(TD ±1.0))
    $(TR $(TD any) $(TD +∞) $(TD ±0.0))
)
*/
@IEEECompliant("atan2Pi", 43)
auto atan2pi(D1, D2)(auto const ref D1 y, auto const ref D2 x)
if (isDecimal!(D1, D2))
{
    alias D = CommonDecimal!(D1, D2);
    D result;
    auto flags = decimalAtan2Pi(y, x, result, 
                              __ctfe ? D.PRECISION : DecimalControl.precision, 
                              __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= ExceptionFlags.invalidOperation | ExceptionFlags.underflow | ExceptionFlags.inexact;
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 y = 10;
    decimal32 x = 0;
    assert (atan2pi(y, x) == decimal32("0.5"));
}

unittest
{

    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert (isNaN(atan2(T.nan, T.zero)));
        assert (isNaN(atan2(T.one, T.nan)));
        assert (atan2pi(T.zero, -T.zero) == T.one); 
        assert (atan2pi(-T.zero, -T.zero) == -T.one); 
        assert (atan2pi(T.zero, T.zero) == T.zero);
        assert (atan2pi(-T.zero, T.zero) == -T.zero); 
        assert (atan2pi(T.zero, -T.one) == T.one);
        assert (atan2pi(-T.zero, -T.one) == -T.one);
        assert (atan2pi(T.zero, T.one) == T.zero);
        assert (atan2pi(-T.zero, T.one) == -T.zero);
        assert (atan2pi(-T.one, T.zero) == -T.half);
        assert (atan2pi(T.one, T.zero) == T.half);
        assert (atan2pi(T.one, -T.infinity) == T.one);
        assert (atan2pi(-T.one, -T.infinity) == -T.one);
        assert (atan2pi(T.one, T.infinity) == T.zero);
        assert (atan2pi(-T.one, T.infinity) == -T.zero);
        assert (atan2pi(-T.infinity, T.one) == -T.half);
        assert (atan2pi(T.infinity, T.one) == T.half);
        assert (atan2pi(-T.infinity, -T.infinity) == -T.threequarters);
        assert (atan2pi(T.infinity, -T.infinity) == T.threequarters);
        assert (atan2pi(-T.infinity, T.infinity) == -T.quarter);
        assert (atan2pi(T.infinity, T.infinity) == T.quarter);
    }
}

/**
Calculates the inverse hyperbolic tangent of x
Exceptions:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN or |x| > 1.0))
    $(TR $(TD $(MYREF DivisionByZeroException)) 
         $(TD |x| = 1.0))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD the result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH atanh(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD ±0.0))
    $(TR $(TD ±1.0) $(TD ±∞))
    $(TR $(TD >1.0) $(TD NaN))
    $(TR $(TD <1.0) $(TD NaN))
)
*/
@IEEECompliant("atanh", 43)
D atanh(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalAtanh(result, 
                             __ctfe ? D.PRECISION : DecimalControl.precision, 
                             __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= ExceptionFlags.invalidOperation | ExceptionFlags.underflow | 
             ExceptionFlags.inexact | ExceptionFlags.divisionByZero;
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 x = 0;
    assert (atanh(x) == 0);
}

/**
Calculates the arc tangent of x divided by π, returning a value ranging from -1/2 to 1/2.
Exceptions:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD the result is too small to be represented))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH atan(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD ±0.0))
    $(TR $(TD ±∞) $(TD ±1/2))
)
*/
@IEEECompliant("atanPi", 43)
D atanpi(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalAtanPi(result, 
                              __ctfe ? D.PRECISION : DecimalControl.precision, 
                              __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= ExceptionFlags.invalidOperation | ExceptionFlags.underflow | ExceptionFlags.inexact;
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 radians = 1;
    assert (atanpi(radians) == decimal32("0.25"));
}


unittest
{
    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert (isIdentical(atanpi(T.zero), T.zero));
        assert (isIdentical(atanpi(-T.zero), -T.zero));
        assert (isIdentical(atanpi(T.infinity), T.half));
        assert (isIdentical(atanpi(-T.infinity), -T.half));
        assert (isNaN(atanpi(T.nan)));
    }
}

/**
Computes the cubic root of x
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD cubic root of x is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH cbrt(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD ±0.0))
    $(TR $(TD ±∞) $(TD ±∞))
)
*/
D cbrt(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalCbrt(result, 
                            __ctfe ? D.PRECISION : DecimalControl.precision, 
                            __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 x = 27;
    assert (cbrt(x) == 3);
}

/**
Returns the value of x rounded upward to the next integer (toward positive infinity).
This operation is silent, doesn't throw any exception.
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH ceil(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD ±0.0))
    $(TR $(TD ±∞) $(TD ±∞))
)
*/
D ceil(D)(auto const ref D x)
{
    auto result = canonical(x);
    if (isNaN(x) || isInfinity(x) || isZero(x))
        return result;
    decimalRound(result, 0, RoundingMode.towardPositive);
    return result;
}

///
unittest
{
    assert (ceil(decimal32("123.456")) == 124);
    assert (ceil(decimal32("-123.456")) == -123);
}

/**
Defines a total order on all _decimal values.
Params:
    x = a _decimal value
    y = a _decimal value
Returns:
    -1 if x precedes y, 0 if x is equal to y, +1 if x follows y
Notes:
    The total order is defined as:<br/>
    - -sNaN < -NaN < -infinity < -finite < -0.0 < +0.0 < +finite < +infinity < +NaN < +sNaN<br/>
    - for two NaN values the total order is defined based on the payload 
*/
int cmp(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!(D1, D2))
{
    bool sx = cast(bool)(x.data & D1.MASK_SGN);
    bool sy = cast(bool)(y.data & D2.MASK_SGN);

    if (sx != sy)
        return sx ? -1 : 1;
   

    if (isSignaling(x))
    {
        if (isSignaling(y))
        {
            auto px = x.data & D1.MASK_PAYL;
            auto py = y.data & D2.MASK_PAYL;
            if (px > py)
                return sx ? -1 : 1;
            else if (px < py)
                return sx ? 1 : -1;
            else
                return 0;
        }
        return sx ? -1 : 1;
    }

    if (isNaN(x))
    {
        if (isNaN(y) && !isSignaling(y))
        {
            auto px = x.data & D1.MASK_PAYL;
            auto py = y.data & D2.MASK_PAYL;
            if (px > py)
                return sx ? -1 : 1;
            else if (px < py)
                return sx ? 1 : -1;
            else
                return 0;
        }
        if (isSignaling(y))
            return sx ? 1 : -1;
        else
            return sx ? -1 : 1;
    }

    if (isInfinity(x))
    {
        if (isNaN(y))
            return sx ? 1 : -1;
        else
            return sx ? -1 : 1;
    }

    if (!isFinite(y))
        return sx ? 1 : -1;

    if (isZero(x))
    {
        if (isZero(y))
            return sx ? -1 : 1;
        else
            return sy ? 1 : -1;
    }

    if (isZero(y))
        return sx ? -1 : 1;

    DataType!D1 cx;
    DataType!D2 cy;
    int ex, ey;
    x.unpack(cx, ex);
    y.unpack(cy, ey);

    alias D = CommonDecimal!(D1, D2);
    static if (is(D == Unqual!D1))
        alias cxx = cx; 
    else
        DataType!D2 cxx = cx;

    static if (is(D == D2))
        alias cyy = cy; 
    else
        DataType!D1 cyy = cy;

    int px = prec(cxx);
    int py = prec(cyy);

    if (px > py)
    {
        ey -= px - py;
        if (ex > ey)
            return sx ? -1 : 1;
        else if (ex < ey)
            return sx ? 1 : -1;
        mulpow10(cyy, px - py);

    }
    else if (px < py)
    {
        ex -= py - px;
        if (ex > ey)
            return sx ? -1 : 1;
        else if (ex < ey)
            return sx ? 1 : -1;
        mulpow10(cxx, py - px);            
    }

    if (ex > ey)
        return sx ? -1 : 1;
    else if (ex < ey)
        return sx ? 1 : -1;

    if (cxx > cyy)
        return sx ? -1 : 1;
    else if (cxx < cyy)
        return sx ? 1 : -1;

    return 0;
}

///
unittest
{
    assert (cmp(-decimal32.nan, decimal64.max) == -1);
    assert (cmp(decimal32.max, decimal128.min_normal) == 1);
    assert (cmp(decimal64(0), -decimal64(0)) == 1);
}
/**
Computes (1 + x)$(SUPERSCRIPT n) where n is an integer
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN or x < -1.0))
    $(TR $(TD $(MYREF DivisionByZeroException)) 
         $(TD x = -1.0 and n < 0))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH n) $(TH compound(x, n)))
    $(TR $(TD sNaN) $(TD any) $(TD NaN))
    $(TR $(TD any) $(TD 0) $(TD +1.0))
    $(TR $(TD -1.0) $(TD <0) $(TD +∞))
    $(TR $(TD -1.0) $(TD >0) $(TD +0.0))
    $(TR $(TD +∞) $(TD any) $(TD +∞))
)
*/
@IEEECompliant("compound", 42)
auto compound(D)(auto const ref D x, const int n)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalCompound(result, n,
                               __ctfe ? D.PRECISION : DecimalControl.precision, 
                               __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    DecimalControl.raiseFlags(flags);
    return result;
}

unittest
{
    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert (compound(T.ten, 0) == 1);
        assert (compound(T.infinity, 0) == 1);
        assert (compound(-T.one, 0) == 1);
        assert (compound(T.zero, 0) == 1);
        assert (compound(-T.one, 5) == 0);
        assert (compound(T.infinity, 5) == T.infinity);
    }
}

///
unittest
{
    decimal32 x = "0.2";
    assert (compound(x, 2) == decimal32("1.44"));
}

/**
Copies the sign of a _decimal value _to another.
This operation is silent, no error flags are set and no exceptions are thrown.
Params:
    to = a _decimal value to copy
    from = a _decimal value from which the sign is copied
Returns: 
    to with the sign of from
*/
@IEEECompliant("copySign", 23)
D1 copysign(D1, D2)(auto const ref D1 to, auto const ref D2 from)
if (isDecimal!(D1, D2))
{
    Unqual!D1 result = to;
    if ((from.data & D2.MASK_SGN) == D2.MASK_SGN)
        result.data |= D1.MASK_SGN;
    else
        result.data &= ~D1.MASK_SGN;
    return result;
}

///
unittest
{
    decimal32 negative = -decimal32.min_normal;
    decimal64 test = decimal64.max;
    assert(copysign(test, negative) == -decimal64.max);

}

/**
Returns cosine of x.
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN or ±∞))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH cos(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±∞) $(TD NaN))
    $(TR $(TD ±0.0) $(TD +1.0))
    $(TR $(TD π/6) $(TD +√3/2))
    $(TR $(TD π/4) $(TD +√2/2))
    $(TR $(TD π/3) $(TD +0.5))
    $(TR $(TD π/2) $(TD +0.0))
    $(TR $(TD 2π/3) $(TD -0.5))
    $(TR $(TD 3π/4) $(TD -√2/2))
    $(TR $(TD 5π/6) $(TD -√3/2))
    $(TR $(TD π) $(TD -1.0))
)
*/
@IEEECompliant("cos", 42)
D cos(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalCos(result, 
                             __ctfe ? D.PRECISION : DecimalControl.precision, 
                             __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    DecimalControl.raiseFlags(flags);
    return result;
}


/**
Calculates the hyperbolic cosine of x.
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH cosh(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±∞) $(TD +∞))
    $(TR $(TD ±0.0) $(TD +1.0))
)
*/
@IEEECompliant("cosh", 42)
D cosh(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalCosh(result, 
                            __ctfe ? D.PRECISION : DecimalControl.precision, 
                            __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    DecimalControl.raiseFlags(flags);
    return result;
}

//unittest
//{
//    import std.stdio;
//    import std.math;
//    for(int i = 1; i < 10; ++i)
//    {
//        writefln("+%3.2f %35.34f %35.34f", i/10.0, cosh(decimal128(i)/10), std.math.cosh(i/10.0));
//    }
//}

/**
Returns cosine of xπ.
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN or ±∞))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH cospi(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±∞) $(TD NaN))
    $(TR $(TD ±0.0) $(TD +1.0))
    $(TR $(TD 1/6) $(TD +√3/2))
    $(TR $(TD 1/4) $(TD +√2/2))
    $(TR $(TD 1/3) $(TD +0.5))
    $(TR $(TD 1/2) $(TD +0.0))
    $(TR $(TD 2/3) $(TD -0.5))
    $(TR $(TD 3/4) $(TD -√2/2))
    $(TR $(TD 5/6) $(TD -√3/2))
    $(TR $(TD 1.0) $(TD -1.0))
)
*/
@IEEECompliant("cosPi", 42)
D cospi(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalCosPi(result, 
                             __ctfe ? D.PRECISION : DecimalControl.precision, 
                             __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    DecimalControl.raiseFlags(flags);
    return result;
}

///IEEE-754-2008 floating point categories
enum DecimalClass
{
    ///a signalling NaN represents most of the time an uninitialized variable; 
    ///a quiet NaN represents the result of an invalid operation
    signalingNaN,
    ///ditto
    quietNaN,
    ///value represents infinity
    negativeInfinity,
    ///ditto
    positiveInfinity,
    ///value represents a normalized _decimal value
    negativeNormal,
    ///ditto
    positiveNormal,
    ///value represents a subnormal _decimal value
    negativeSubnormal,
    ///ditto
    positiveSubnormal,
    ///value is 0
    negativeZero,
    ///ditto
    positiveZero,
}

/**
Returns the decimal class where x falls into.
This operation is silent, no exception flags are set and no exceptions are thrown.
Params:
    x = a _decimal value
Returns: 
    One of the members of $(MYREF DecimalClass) enumeration
*/
@IEEECompliant("class", 25)
DecimalClass decimalClass(D)(auto const ref D x) 
if (isDecimal!D)
{
    DataType!D coefficient;
    uint exponent;

    if ((x.data & D.MASK_INF) == D.MASK_INF)
        if ((x.data & D.MASK_QNAN) == D.MASK_QNAN)
            if ((x.data & D.MASK_SNAN) == D.MASK_SNAN)
                return DecimalClass.signalingNaN;
            else
                return DecimalClass.quietNaN;
        else
            return x.data & D.MASK_SGN ? DecimalClass.negativeInfinity : DecimalClass.positiveInfinity;
    else if ((x.data & D.MASK_EXT) == D.MASK_EXT)
    {
        coefficient = (x.data & D.MASK_COE2) | D.MASK_COEX;
        if (coefficient > D.COEF_MAX)
            return x.data & D.MASK_SGN ? DecimalClass.negativeZero : DecimalClass.positiveZero; 
        exponent = cast(uint)((x.data & D.MASK_EXP2) >>> D.SHIFT_EXP2);
    }
    else
    {
        coefficient = x.data & D.MASK_COE1;
        if (coefficient == 0U)
            return (x.data & D.MASK_SGN) == D.MASK_SGN ? DecimalClass.negativeZero : DecimalClass.positiveZero; 
        exponent = cast(uint)((x.data & D.MASK_EXP1) >>> D.SHIFT_EXP1);
    }

  

    bool isNegative = (x.data & D.MASK_SGN) == D.MASK_SGN;

    if (exponent < D.PRECISION - 1)
    {
        if (prec(coefficient) < D.PRECISION - exponent)
            return x.data & D.MASK_SGN ? DecimalClass.negativeSubnormal : DecimalClass.positiveSubnormal;
    }
    return x.data & D.MASK_SGN ? DecimalClass.negativeNormal : DecimalClass.positiveNormal;
}

///
unittest
{
    assert(decimalClass(decimal32.nan) == DecimalClass.quietNaN);
    assert(decimalClass(decimal64.infinity) == DecimalClass.positiveInfinity);
    assert(decimalClass(decimal128.max) == DecimalClass.positiveNormal);
    assert(decimalClass(-decimal32.max) == DecimalClass.negativeNormal);
    assert(decimalClass(decimal128.epsilon) == DecimalClass.positiveNormal);
}

unittest
{
    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert(decimalClass(T.snan) == DecimalClass.signalingNaN);
        assert(decimalClass(T.qnan) == DecimalClass.quietNaN);
        assert(decimalClass(T.minusInfinity) == DecimalClass.negativeInfinity);
        assert(decimalClass(T.infinity) == DecimalClass.positiveInfinity);
        assert(decimalClass(T.zero) == DecimalClass.positiveZero);
        assert(decimalClass(T.minusZero) == DecimalClass.negativeZero);
        assert(decimalClass(T.subn) == DecimalClass.positiveSubnormal);
        assert(decimalClass(T.minusSubn) == DecimalClass.negativeSubnormal);
        assert(decimalClass(T.ten) == DecimalClass.positiveNormal);
        assert(decimalClass(T.minusTen) == DecimalClass.negativeNormal);
        assert(decimalClass(T.max) == DecimalClass.positiveNormal);
        assert(decimalClass(-T.max) == DecimalClass.negativeNormal);
        assert(decimalClass(T.min_normal) == DecimalClass.positiveNormal);
        assert(decimalClass(T.epsilon) == DecimalClass.positiveNormal);
    }
}



/**
Sums x$(SUBSCRIPT i) * y$(SUBSCRIPT i) using a higher precision, rounding only once at the end.
Returns:
    x$(SUBSCRIPT 0) * y$(SUBSCRIPT 0) + x$(SUBSCRIPT 1) * y$(SUBSCRIPT 1) + ... + x$(SUBSCRIPT n) * y$(SUBSCRIPT n)
Notes:
    If x and y arrays are not of the same length, operation is performed for min(x.length, y.length);
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD any x is signaling NaN))
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD any combination of elements is (±∞, ±0.0) or (±0.0, ±∞)))
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD there are two products resulting in infinities of different sign))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD result is inexact))
)
*/
@IEEECompliant("dot", 47)
D dot(D)(const(D)[] x, const(D)[] y)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalDot(x, y, result, 
                            __ctfe ? D.PRECISION : DecimalControl.precision, 
                            __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= (ExceptionFlags.inexact | ExceptionFlags.invalidOperation | ExceptionFlags.overflow | ExceptionFlags.underflow);
    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Calculates e$(SUPERSCRIPT x)
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD e$(SUPERSCRIPT x) is too small to be represented))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD e$(SUPERSCRIPT x) is too big to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH exp(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD +1.0))
    $(TR $(TD -∞) $(TD 0))
    $(TR $(TD +∞) $(TD +∞))
)
*/
@IEEECompliant("exp", 42)
D exp(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalExp(result, 
                            __ctfe ? D.PRECISION : DecimalControl.precision, 
                            __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= (ExceptionFlags.inexact | ExceptionFlags.invalidOperation | ExceptionFlags.overflow | ExceptionFlags.underflow);
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 power = 1;
    assert (exp(power) == decimal32.E);
}

unittest
{
    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert (exp(T.zero) == T.one);
        assert (exp(-T.infinity) == T.zero);
        assert (exp(T.infinity) == T.infinity);
        assert (isNaN(exp(T.nan)));
    }
}

/**
Calculates 10$(SUPERSCRIPT x)
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD 10$(SUPERSCRIPT x) is too small to be represented))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD 10$(SUPERSCRIPT x) is too big to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH exp10(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD +1.0))
    $(TR $(TD -∞) $(TD +0.0))
    $(TR $(TD +∞) $(TD +∞))
)
*/
@IEEECompliant("exp10", 42)
D exp10(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalExp10(result, 
                            __ctfe ? D.PRECISION : DecimalControl.precision, 
                            __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= (ExceptionFlags.inexact | ExceptionFlags.invalidOperation | ExceptionFlags.overflow | ExceptionFlags.underflow);
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 x = 3;
    assert(exp10(x) == 1000);
}


/**
Calculates 10$(SUPERSCRIPT x) - 1
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD 10$(SUPERSCRIPT x) - 1 is too small to be represented))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD 10$(SUPERSCRIPT x) - 1 is too big to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH exp10m1(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD ±0.0))
    $(TR $(TD -∞) $(TD -1.0))
    $(TR $(TD +∞) $(TD +∞))
)
*/
@IEEECompliant("exp10m1", 42)
D exp10m1(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalExp10m1(result, 
                              __ctfe ? D.PRECISION : DecimalControl.precision, 
                              __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= (ExceptionFlags.inexact | ExceptionFlags.invalidOperation | ExceptionFlags.overflow | ExceptionFlags.underflow);
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 x = 3;
    assert(exp10m1(x) == 999);
}

/**
Calculates 2$(SUPERSCRIPT x)
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD 2$(SUPERSCRIPT x) is too small to be represented))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD 2$(SUPERSCRIPT x) is too big to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH exp2(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD +1.0))
    $(TR $(TD -∞) $(TD +0.0))
    $(TR $(TD +∞) $(TD +∞))
)
*/
@IEEECompliant("exp2", 42)
D exp2(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalExp2(result, 
                              __ctfe ? D.PRECISION : DecimalControl.precision, 
                              __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= (ExceptionFlags.inexact | ExceptionFlags.invalidOperation | ExceptionFlags.overflow | ExceptionFlags.underflow);
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 x = 3;
    assert(exp2(x) == 8);
}

/**
Calculates 2$(SUPERSCRIPT x) - 1
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD 2$(SUPERSCRIPT x) - 1 is too small to be represented))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD 2$(SUPERSCRIPT x) - 1 is too big to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH exp2m1(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD ±0.0))
    $(TR $(TD -∞) $(TD -1.0))
    $(TR $(TD +∞) $(TD +∞))
)
*/
@IEEECompliant("exp2m1", 42)
D exp2m1(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalExp2m1(result, 
                             __ctfe ? D.PRECISION : DecimalControl.precision, 
                             __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= (ExceptionFlags.inexact | ExceptionFlags.invalidOperation | ExceptionFlags.overflow | ExceptionFlags.underflow);
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 x = 3;
    assert(exp2m1(x) == 7);
}

/**
Calculates e$(SUPERSCRIPT x) - 1
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD e$(SUPERSCRIPT x) - 1 is too small to be represented))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD e$(SUPERSCRIPT x) - 1 is too big to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH expm1(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD ±0.0))
    $(TR $(TD -∞) $(TD -1.0))
    $(TR $(TD +∞) $(TD +∞))
)
*/
@IEEECompliant("expm1", 42)
D expm1(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalExpm1(result, 
                               __ctfe ? D.PRECISION : DecimalControl.precision, 
                               __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= (ExceptionFlags.inexact | ExceptionFlags.invalidOperation | ExceptionFlags.overflow | ExceptionFlags.underflow);
    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Returns the value of x rounded downward to the previous integer (toward negative infinity).
This operation is silent, doesn't throw any exception.
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH floor(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD ±0.0))
    $(TR $(TD ±∞) $(TD ±∞))
)
*/
D floor(D)(auto const ref D x)
{
    auto result = canonical(x);
    if (isNaN(x) || isInfinity(x) || isZero(x))
        return result;
    decimalRound(result, 0, RoundingMode.towardNegative);
    return result;
}

///
unittest
{
    assert (floor(decimal32("123.456")) == 123);
    assert (floor(decimal32("-123.456")) == -124);
}

/**
Returns (x * y) + z, rounding only once according to the current precision and rounding mode
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x, y or z is signaling NaN))
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD (x, y) = (±∞, ±0.0) or (±0.0, ±∞)))
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x or y is infinite, z is infinite but has opposing sign))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH y) $(TH z) $(TH fma(x, y, z)))
    $(TR $(TD NaN) $(TD any) $(TD any) $(TD NaN))
    $(TR $(TD any) $(TD NaN) $(TD any) $(TD NaN))
    $(TR $(TD any) $(TD any) $(TD NaN) $(TD NaN))
    $(TR $(TD ±∞) $(TD ±0.0) $(TD any) $(TD NaN))
    $(TR $(TD ±0.0) $(TD ±∞) $(TD any) $(TD NaN))
    $(TR $(TD +∞) $(TD >0.0) $(TD -∞) $(TD NaN))
    $(TR $(TD -∞) $(TD <0.0) $(TD -∞) $(TD NaN))
    $(TR $(TD -∞) $(TD <0.0) $(TD -∞) $(TD NaN))
    $(TR $(TD +∞) $(TD >0.0) $(TD -∞) $(TD NaN))
    $(TR $(TD -∞) $(TD >0.0) $(TD +∞) $(TD NaN))
    $(TR $(TD +∞) $(TD <0.0) $(TD +∞) $(TD NaN))
    $(TR $(TD +∞) $(TD <0.0) $(TD +∞) $(TD NaN))
    $(TR $(TD -∞) $(TD >0.0) $(TD +∞) $(TD NaN))
    $(TR $(TD >0.0) $(TD +∞) $(TD -∞) $(TD NaN))
    $(TR $(TD <0.0) $(TD -∞) $(TD -∞) $(TD NaN))
    $(TR $(TD <0.0) $(TD -∞) $(TD -∞) $(TD NaN))
    $(TR $(TD >0.0) $(TD +∞) $(TD -∞) $(TD NaN))
    $(TR $(TD >0.0) $(TD -∞) $(TD +∞) $(TD NaN))
    $(TR $(TD <0.0) $(TD +∞) $(TD +∞) $(TD NaN))
    $(TR $(TD <0.0) $(TD +∞) $(TD +∞) $(TD NaN))
    $(TR $(TD >0.0) $(TD -∞) $(TD +∞) $(TD NaN))
    $(TR $(TD +∞) $(TD >0.0) $(TD +∞) $(TD +∞))
    $(TR $(TD -∞) $(TD <0.0) $(TD +∞) $(TD +∞))
    $(TR $(TD +∞) $(TD <0.0) $(TD -∞) $(TD -∞))
    $(TR $(TD -∞) $(TD >0.0) $(TD -∞) $(TD -∞))
    $(TR $(TD >0.0) $(TD +∞) $(TD +∞) $(TD +∞))
    $(TR $(TD <0.0) $(TD -∞) $(TD +∞) $(TD +∞))
    $(TR $(TD <0.0) $(TD +∞) $(TD -∞) $(TD -∞))
    $(TR $(TD >0.0) $(TD -∞) $(TD -∞) $(TD -∞))
    $(TR $(TD +∞) $(TD >0.0) $(TD any) $(TD +∞))
    $(TR $(TD -∞) $(TD <0.0) $(TD any) $(TD +∞))
    $(TR $(TD +∞) $(TD <0.0) $(TD any) $(TD -∞))
    $(TR $(TD -∞) $(TD >0.0) $(TD any) $(TD -∞))
    $(TR $(TD >0.0) $(TD +∞) $(TD any) $(TD +∞))
    $(TR $(TD <0.0) $(TD -∞) $(TD any) $(TD +∞))
    $(TR $(TD <0.0) $(TD +∞) $(TD any) $(TD -∞))
    $(TR $(TD >0.0) $(TD -∞) $(TD any) $(TD -∞))
)
*/
@IEEECompliant("fusedMultiplyAdd", 4)
auto fma(D1, D2, D3)(auto const ref D1 x, auto const ref D2 y, auto const ref D3 z)
if (isDecimal!(D1, D2, D3))
{
    alias D = CommonDecimal!(D1, D2, D3);
    D result;
    auto flags = decimalFMA!(D1, D2, D3)(x, y, z, result, 
                        __ctfe ? D.PRECISION : DecimalControl.precision, 
                        __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 x = 2;
    decimal64 y = 3;
    decimal128 z = 5;
    assert (fma(x, y, z) == 11);
}

/**
Returns the larger _decimal value between x and y
Throws:
    $(MYREF InvalidOperationException) if x or y is signaling NaN
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH y) $(TH fmax(x, y)))
    $(TR $(TD NaN) $(TD any) $(TD y))
    $(TR $(TD any) $(TD NaN) $(TD x))
)
*/
@IEEECompliant("maxNum", 19)
auto fmax(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!D1 && isDecimal!D2)
{
    CommonDecimal!(D1, D2) result;
    auto flags = decimalMax(x, y, result) & ExceptionFlags.invalidOperation;
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 x = 3;
    decimal64 y = -4;
    assert (fmax(x, y) == 3);
}

/**
Returns the larger _decimal value between absolutes of x and y
Throws:
    $(MYREF InvalidOperationException) if x or y is signaling NaN
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH y) $(TH fmaxAbs(x, y)))
    $(TR $(TD NaN) $(TD any) $(TD y))
    $(TR $(TD any) $(TD NaN) $(TD x))
)
*/
@IEEECompliant("maxNumMag", 19)
auto fmaxAbs(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!D1 && isDecimal!D2)
{
    CommonDecimal!(D1, D2) result;
    auto flags = decimalMaxAbs(x, y, result) & ExceptionFlags.invalidOperation;
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 x = 3;
    decimal64 y = -4;
    assert (fmaxAbs(x, y) == -4);
}

/**
Returns the smaller _decimal value between x and y
Throws:
    $(MYREF InvalidOperationException) if x or y is signaling NaN
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH y) $(TH fmin(x, y)))
    $(TR $(TD NaN) $(TD any) $(TD y))
    $(TR $(TD any) $(TD NaN) $(TD x))
)
*/
@IEEECompliant("minNum", 19)
auto fmin(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!D1 && isDecimal!D2)
{
    CommonDecimal!(D1, D2) result;
    auto flags = decimalMin(x, y, result) & ExceptionFlags.invalidOperation;
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 x = 3;
    decimal64 y = -4;
    assert (fmin(x, y) == -4);
}

/**
Returns the smaller _decimal value between absolutes of x and y
Throws:
    $(MYREF InvalidOperationException) if x or y is signaling NaN
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH y) $(TH fminAbs(x, y)))
    $(TR $(TD NaN) $(TD any) $(TD y))
    $(TR $(TD any) $(TD NaN) $(TD x))
)
*/
@IEEECompliant("minNumMag", 19)
auto fminAbs(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!D1 && isDecimal!D2)
{
    CommonDecimal!(D1, D2) result;
    auto flags = decimalMinAbs(x, y, result) & ExceptionFlags.invalidOperation;
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 x = 3;
    decimal64 y = -4;
    assert (fminAbs(x, y) == 3);
}

/**
Calculates the remainder of the division x / y
Params:
    x = dividend
    y = divisor
Returns:
    The value of x - n * y, where n is the quotient rounded toward zero of the division x / y  
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x or y is signaling NaN, x = ±∞, y = ±0.0))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF DivisionByZeroException)) 
         $(TD y = 0.0))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH y) $(TH fmod(x, y)))
    $(TR $(TD NaN) $(TD any) $(TD NaN))
    $(TR $(TD any) $(TD NaN) $(TD NaN))
    $(TR $(TD ±∞) $(TD any) $(TD NaN))
    $(TR $(TD any) $(TD 0.0) $(TD NaN))
    $(TR $(TD any) $(TD ±∞) $(TD NaN))
)
*/
auto fmod(D1, D2)(auto const ref D1 x, auto const ref D2 y)
{
    alias D = CommonDecimal!(D1, D2);
    D result = x;
    auto flags = decimalMod(result, y, 
                            __ctfe ? D.PRECISION : DecimalControl.precision, 
                            RoundingMode.towardZero);
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 x = "18.5";
    decimal32 y = "4.2";
    assert (fmod(x, y) == decimal32("1.7"));
}


/**
Separates _decimal _value into coefficient and exponent. 
This operation is silent, doesn't throw any exception.
Returns:
    a result such as x = result * 10$(SUPERSCRIPT y) and |result| < 10.0
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH y) $(TH frexp(x, y)))
    $(TR $(TD NaN) $(TD int.min) $(TD NaN))
    $(TR $(TD +∞) $(TD int.max) $(TD +∞))
    $(TR $(TD -∞) $(TD int.min) $(TD -∞))
    $(TR $(TD ±0.0) $(TD 0) $(TD ±0.0))
)
*/
D frexp(D)(auto const ref D x, out int y)
{
    if (isNaN(x))
    {
        y = int.min;
        return x;
    }

    if (isInfinity(x))
    {
        y = signbit(x) ? int.min : int.max;
        return x;
    }

    if (isZero(x))
    {
        y = 0;
        return canonical(value);
    }

    Unqual!D result;
    DataType!D cx;
    bool sx = x.unpack(cx, y);
    coefficientShrink(cx, y);
    auto p = prec(cx);
    y -= p - 1;
    result.pack(cx, p - 1, sx);
    return result;
}
/**
Extracts the current payload from a NaN value
Note:
    These functions do not check if x is truly a NaN value
    before extracting the payload. Using them on finite values will extract a part of the coefficient
*/
@nogc nothrow pure @safe
uint getNaNPayload(const decimal32 x)
{
    return x.data & decimal32.MASK_PAYL;
}

///ditto
@nogc nothrow pure @safe
ulong getNaNPayload(const decimal64 x)
{
    return x.data & decimal64.MASK_PAYL;
}

///ditto
@nogc nothrow pure @safe
ulong getNaNPayload(const decimal128 x, out ulong payloadHi)
{
    auto payload = x.data & decimal128.MASK_PAYL;
    payloadHi = payload.hi;
    return payload.lo;
}

///
unittest
{
    decimal32 x = decimal32("nan(123)");
    decimal64 y = decimal64("nan(456)");
    decimal128 z = decimal128("nan(789)");

    assert (getNaNPayload(x) == 123);
    assert (getNaNPayload(y) == 456);
    ulong hi;
    assert (getNaNPayload(z, hi) == 789 && hi == 0);

}


/**
Calculates the length of the hypotenuse of a right-angled triangle with sides 
of length x and y. The hypotenuse is the value of the square root of the sums 
of the squares of x and y.
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x, y is signaling NaN))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH y) $(TH hypot(x, y)))
    $(TR $(TD NaN) $(TD NaN) $(TD nan))
    $(TR $(TD ±∞) $(TD any) $(TD +∞))
    $(TR $(TD any) $(TD ±∞) $(TD +∞))
    $(TR $(TD NaN) $(TD any) $(TD nan))
    $(TR $(TD any) $(TD NaN) $(TD nan))
    $(TR $(TD 0.0) $(TD any) $(TD y))
    $(TR $(TD any) $(TD 0.0) $(TD x))
)
*/
@IEEECompliant("hypot", 42)
auto hypot(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!D1 && isDecimal!D2)
{
    alias D = CommonDecimal!(D1, D2);
    D result;
    auto flags = decimalHypot(x, y, result, 
                              __ctfe ? D.PRECISION : DecimalControl.precision,
                              __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    decimal32 x = 3;
    decimal32 y = 4;
    assert (hypot(x, y) == 5);
}

/**
Returns the 10-exponent of x as a signed integral value..
Throws:
    $(MYREF InvalidOperationException) if x is NaN, infinity or 0
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH ilogb(x)))
    $(TR $(TD NaN) $(TD int.min))
    $(TR $(TD ±∞) $(TD int min + 1))
    $(TR $(TD ±0.0) $(TD int.min + 2))
    $(TR $(TD ±1.0) $(TD 0))
)
*/
@IEEECompliant("logB", 17)
int ilogb(D)(auto const ref D x)
if (isDecimal!D)
{
    int result;
    auto flags = decimalLog(x, result);
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    assert (ilogb(decimal32(1234)) == 3);
}

/**
Determines if x is canonical.
This operation is silent, no error flags are set and no exceptions are thrown.
Params:
x = a _decimal value
Returns: 
    true if x is canonical, false otherwise
Notes:
    A _decimal value is considered canonical:<br/>
    - if the value is NaN, the payload must be less than 10 $(SUPERSCRIPT precision - 1);<br/>
    - if the value is infinity, no trailing bits are accepted;<br/>
    - if the value is finite, the coefficient must be less than 10 $(SUPERSCRIPT precision). 
*/
@IEEECompliant("isCanonical", 25)
bool isCanonical(D)(auto const ref D x)
if (isDecimal!D)
{
    if ((x.data & D.MASK_QNAN) == D.MASK_QNAN)
        return (x.data & D.MASK_PAYL) <= D.PAYL_MAX && (x.data & ~(D.MASK_SNAN | D.MASK_SGN | D.MASK_PAYL)) == 0U;
    if ((x.data & D.MASK_INF) == D.MASK_INF)
        return (x.data & ~(D.MASK_INF | D.MASK_SGN)) == 0U;
    if ((x.data & D.MASK_EXT) == D.MASK_EXT)
        return ((x.data & D.MASK_COE2) | D.MASK_COEX) <= D.COEF_MAX;
    return true;
}

///
unittest
{
    assert(isCanonical(decimal32.max));
    assert(isCanonical(decimal64.max));
    assert(!isCanonical(decimal32("nan(0x3fffff)")));

}

unittest
{

    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert(isCanonical(T.zero));
        assert(isCanonical(T.max));
        assert(isCanonical(T.nan));
        assert(isCanonical(T.snan));
        assert(isCanonical(T.infinity));
    }
}

/**
Determines if x is a finite value.
This operation is silent, no error flags are set and no exceptions are thrown.
Params:
    x = a _decimal value
Returns: 
    true if x is finite, false otherwise (NaN or infinity) 
*/
@IEEECompliant("isFinite", 25)
bool isFinite(D)(auto const ref D x)
if (isDecimal!D)
{
    return (x.data & D.MASK_INF) != D.MASK_INF;
}

///
unittest
{
    assert(isFinite(decimal32.max));
    assert(!isFinite(decimal64.nan));
    assert(!isFinite(decimal128.infinity));
}

unittest
{
    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert(isFinite(T.max));
        assert(!isFinite(T.infinity));
        assert(!isFinite(T.snan));
        assert(!isFinite(T.qnan));
    }
}

/**
Checks if two _decimal values are identical
Params:
    x = a _decimal value
    y = a _decimal value
Returns:
    true if x has the same internal representation as y
Notes:
    Even if two _decimal values are equal, their internal representation can be different:<br/>
    - NaN values must have the same sign and the same payload to be considered identical; 
      NaN(12) is not identical to NaN(13)<br/>
    - Zero values must have the same sign and the same exponent to be considered identical; 
      0 * 10$(SUPERSCRIPT 3) is not identical to 0 * 10$(SUPERSCRIPT 5)<br/>
    - Finite _values must be represented based on same exponent to be considered identical;
      123 * 10$(SUPERSCRIPT -3) is not identical to 1.23 * 10$(SUPERSCRIPT -1)
*/
bool isIdentical(D)(auto const ref D x, auto const ref D y)
if (isDecimal!D)
{
    return x.data == y.data;
}

///
unittest
{
    assert (isIdentical(decimal32.min_normal, decimal32.min_normal));
    assert (!isIdentical(decimal64("nan"), decimal64("nan<200>")));
}

/**
Determines if x represents infinity.
This operation is silent, no error flags are set and no exceptions are thrown.
Params:
    x = a _decimal value
Returns: 
    true if x is infinite, false otherwise (NaN or any finite value)
*/
@IEEECompliant("isInfinite", 25)
bool isInfinity(D)(auto const ref D x)
if (isDecimal!D)
{
    return (x.data & D.MASK_INF) == D.MASK_INF && (x.data & D.MASK_QNAN) != D.MASK_QNAN;
}

///
unittest
{
    assert(isInfinity(decimal32.infinity));
    assert(isInfinity(-decimal64.infinity));
    assert(!isInfinity(decimal128.nan));
}

unittest
{
    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert(isInfinity(T.infinity));
        assert(isInfinity(-T.infinity));
        assert(!isInfinity(T.ten));
        assert(!isInfinity(T.snan));
        assert(!isInfinity(T.qnan));
    }
}

/**
Determines if x represents a NaN.
This operation is silent, no error flags are set and no exceptions are thrown.
Params:
    x = a _decimal value
Returns: 
    true if x is NaN (quiet or signaling), false otherwise (any other value than NaN)
*/
@IEEECompliant("isNaN", 25)
bool isNaN(D)(auto const ref D x)
if (isDecimal!D)
{
    return (x.data & D.MASK_QNAN) == D.MASK_QNAN;
}

///
unittest
{
    assert(isNaN(decimal32()));
    assert(isNaN(decimal64.nan));
    assert(!isNaN(decimal128.max));
}

unittest
{
    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert(isNaN(T.snan));
        assert(isNaN(T()));
        assert(!isSignaling(T.ten));
        assert(!isSignaling(T.min_normal));
        assert(isNaN(T.qnan));
    }
}

/**
Determines if x is normalized.
This operation is silent, no error flags are set and no exceptions are thrown.
Params:
    x = a _decimal value
Returns: 
    true if x is normal, false otherwise (NaN, infinity, zero, subnormal)
*/
@IEEECompliant("isNormal", 25)
bool isNormal(D)(auto const ref D x)
if (isDecimal!D)
{
    DataType!D coefficient;
    uint exponent;

    if ((x.data & D.MASK_INF) == D.MASK_INF)
        return false;
    if ((x.data & D.MASK_EXT) == D.MASK_EXT)
    {
        coefficient = (x.data & D.MASK_COE2) | D.MASK_COEX;
        if (coefficient > D.COEF_MAX)
            return false;
        exponent = cast(uint)((x.data & D.MASK_EXP2) >>> D.SHIFT_EXP2);
    }
    else
    {
        coefficient = x.data & D.MASK_COE1;
        if (coefficient == 0U)
            return false;
        exponent = cast(uint)((x.data & D.MASK_EXP1) >>> D.SHIFT_EXP1);
    }  

    if (exponent < D.PRECISION - 1)
        return prec(coefficient) >= D.PRECISION - exponent;

    return true;
}

///
unittest
{
    assert(isNormal(decimal32.max));
    assert(!isNormal(decimal64.nan));
    assert(!isNormal(decimal32("0x1p-101")));
}

unittest
{
   
    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert(!isNormal(T.zero));
        assert(isNormal(T.ten));
        assert(!isNormal(T.nan));
        assert(isNormal(T.min_normal));
        assert(!isNormal(T.subn));
    }
}

/**
Checks whether a _decimal value is a power of ten. This operation is silent, 
no exception flags are set and no exceptions are thrown.
Params:
    x = any _decimal value
Returns:
    true if x is power of ten, false otherwise (NaN, infinity, 0, negative)
*/
bool isPowerOf10(D)(auto const ref D x)
if (isDecimal!D)
{
    if (isNaN(x) || isInfinity(x) || isZero(x) || signbit(x) != 0U)
        return false;

    alias U = DataType!D;
    U c;
    int e;
    x.unpack(c, e);
    coefficientShrink(c, e);
    return c == 1U;
}

///
unittest
{
    assert (isPowerOf10(decimal32("1000")));
    assert (isPowerOf10(decimal32("0.001")));
}

/**
Determines if x represents a signaling NaN.
This operation is silent, no error flags are set and no exceptions are thrown.
Params:
    x = a _decimal value
Returns: 
    true if x is NaN and is signaling, false otherwise (quiet NaN, any other value)
*/
@IEEECompliant("isSignaling", 25)
bool isSignaling(D)(auto const ref D x)
if (isDecimal!D)
{
    return (x.data & D.MASK_SNAN) == D.MASK_SNAN;
}

///
unittest
{
    assert(isSignaling(decimal32()));
    assert(!isSignaling(decimal64.nan));
    assert(!isSignaling(decimal128.max));
}

unittest
{
    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert(isSignaling(T.snan));
        assert(isSignaling(T()));
        assert(!isSignaling(T.ten));
        assert(!isSignaling(T.min_normal));
        assert(!isSignaling(T.qnan));
    }
}

/**
Determines if x is subnormal (denormalized).
This operation is silent, no error flags are set and no exceptions are thrown.
Params:
    x = a _decimal value
Returns: 
    true if x is subnormal, false otherwise (NaN, infinity, zero, normal)
*/
@IEEECompliant("isSubnormal", 25)
bool isSubnormal(D)(auto const ref D x)
if (isDecimal!D)
{
    DataType!D coefficient;
    uint exponent;

    if ((x.data & D.MASK_INF) == D.MASK_INF)
        return false;
    if ((x.data & D.MASK_EXT) == D.MASK_EXT)
    {
        coefficient = (x.data & D.MASK_COE2) | D.MASK_COEX;
        if (coefficient > D.COEF_MAX)
            return false;
        exponent = cast(uint)((x.data & D.MASK_EXP2) >>> D.SHIFT_EXP2);
    }
    else
    {
        coefficient = x.data & D.MASK_COE1;
        if (coefficient == 0U)
            return false;
        exponent = cast(uint)((x.data & D.MASK_EXP1) >>> D.SHIFT_EXP1);
    }  

    if (exponent < D.PRECISION - 1)
        return prec(coefficient) < D.PRECISION - exponent;

    return false;
}

///
unittest
{
    assert(isSubnormal(decimal32("0x1p-101")));
    assert(!isSubnormal(decimal32.max));
    assert(!isSubnormal(decimal64.nan));
    
}

unittest
{

    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert(!isSubnormal(T.zero));
        assert(!isSubnormal(T.ten));
        assert(!isSubnormal(T.nan));
        assert(!isSubnormal(T.min_normal));
        assert(isSubnormal(T.subn));
        assert(isSubnormal(-T.subn));
    }
}



/**
Determines if x represents the value zero.
This operation is silent, no error flags are set and no exceptions are thrown.
Params:
    x = a _decimal value
Returns: 
    true if x is zero, false otherwise (any other value than zero)
Standards: 
    If the internal representation of the _decimal data type has a coefficient 
    greater that 10$(SUPERSCRIPT precision) - 1, is considered 0 according to 
    IEEE standard.
*/
@IEEECompliant("isZero", 25)
bool isZero(D)(auto const ref D x)
if (isDecimal!D)
{
    if ((x.data & D.MASK_INF) != D.MASK_INF)
    {
        if ((x.data & D.MASK_EXT) == D.MASK_EXT)
            return ((x.data & D.MASK_COE2) | D.MASK_COEX) > D.COEF_MAX;
        else
            return (x.data & D.MASK_COE1) == 0U;
    }
    else
        return false;
}

///
unittest
{
    assert(isZero(decimal32(0)));
    assert(!isZero(decimal64.nan));
    assert(isZero(decimal32("0x9FFFFFp+10")));
}

unittest
{
    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert(isZero(T.zero));
        assert(isZero(T.minusZero));
        assert(!isZero(T.ten));
        assert(isZero(T(T.MASK_NONE, T.MASK_EXT, T.MASK_COE2 | T.MASK_COEX)));
    }
}



/**
Compares two _decimal operands.
This operation is silent, no exception flags are set and no exceptions are thrown.
Returns:
    true if the specified condition is satisfied
Notes:
    By default, comparison operators will throw $(MYREF InvalidOperationException) or will 
    set the $(MYREF ExceptionFlags.invalidOperation) context flag if a trap is not set.
    The equivalent functions are silent and will not throw any exception (or will not set any flag)
    if a NaN value is encountered.
*/
@IEEECompliant("compareQuietGreater", 24)
bool isGreater(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!(D1, D2))
{
    return decimalCmp(x, y) == 1;
}

///ditto
@IEEECompliant("compareQuietGreaterEqual", 24)
bool isGreaterOrEqual(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!(D1, D2))
{
    return decimalCmp(x, y) >= 0;
}

///ditto
@IEEECompliant("compareQuietGreaterUnordered", 24)
bool isGreaterOrUnordered(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!(D1, D2))
{
    auto result = decimalCmp(x, y);
    return result > 0 || result == -2;
}

///ditto
@IEEECompliant("compareQuietLess", 24)
@IEEECompliant("compareQuietNotLess", 24)
bool isLess(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!(D1, D2))
{
    return decimalCmp(x, y) == -1;
}

///ditto
@IEEECompliant("compareQuietLessEqual", 24)
bool isLessOrEqual(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!(D1, D2))
{
    int result = decimalCmp(x, y);
    return result == -1 || result == 0;
}

///ditto
@IEEECompliant("compareQuietLessUnordered", 24)
bool isLessOrUnordered(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!(D1, D2))
{
    return decimalCmp(x, y) < 0;
}

///ditto
@IEEECompliant("compareQuietNotEqual", 24)
bool isLessOrGreater(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!(D1, D2))
{
    int result = decimalCmp(x, y) >= 0;
    return result == -1 || result == 1;
}

///ditto
@IEEECompliant("compareQuietOrdered", 24)
@IEEECompliant("compareQuietUnordered", 24)
bool isUnordered(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!(D1, D2))
{
    return decimalCmp(x, y) == -2;
}

///
unittest
{
    assert(isUnordered(decimal32.nan, decimal64.max));
    assert(isGreater(decimal32.infinity, decimal128.max));
    assert(isGreaterOrEqual(decimal32.infinity, decimal64.infinity));
    assert(isLess(decimal64.max, decimal128.max));
    assert(isLessOrEqual(decimal32.min_normal, decimal32.min_normal));
    assert(isLessOrGreater(decimal128.max, -decimal128.max));
}

unittest
{
    

    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert(isUnordered(T.nan, T.one));
        assert(isUnordered(T.one, T.nan));
        assert(isUnordered(T.nan, T.nan));

        assert(isGreater(T.max, T.ten));
        assert(isGreater(T.ten, T.one));
        assert(isGreater(-T.ten, -T.max));
        assert(isGreater(T.zero, -T.max));
        assert(isGreater(T.max, T.zero));
        
        assert(isLess(T.one, T.ten), T.stringof);
        assert(isLess(T.ten, T.max));
        assert(isLess(-T.max, -T.one));
        assert(isLess(T.zero, T.max));
        assert(isLess(T.max, T.infinity));
    }
}

/**
Compares two _decimal operands for equality
Returns:
    true if the specified condition is satisfied, false otherwise or if any of the operands is NaN.
Notes:
    By default, $(MYREF Decimal.opEquals) is silent, returning false if a NaN value is encountered.
    isEqual and isNotEqual will throw $(MYREF InvalidOperationException) or will 
    set the $(MYREF ExceptionFlags.invalidOperation) context flag if a trap is not set.
*/

@IEEECompliant("compareSignalingEqual", 24)
bool isEqual(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!(D1, D2))
{
    if (isNaN(x) || isNaN(y))
        DecimalControl.raiseFlags(ExceptionFlags.invalidOperation);
    return decimalEqu(x, y);
}

///ditto
@IEEECompliant("compareSignalingNotEqual", 24)
bool isNotEqual(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!(D1, D2))
{
    if (isNaN(x) || isNaN(y))
    {
        DecimalControl.raiseFlags(ExceptionFlags.invalidOperation);
        return false;
    }
    return !decimalEqu(x, y);
}

///
unittest
{
    assert (isEqual(decimal32.max, decimal32.max));
    assert (isNotEqual(decimal32.max, decimal32.min_normal));
}

/**
Computes x * 10$(SUPERSCRIPT n).
This operation is silent, doesn't throw any exception.
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH n) $(TH ldexp(x, n)))
    $(TR $(TD NaN) $(TD any) $(TD NaN))
    $(TR $(TD ±∞) $(TD any) $(TD ±∞))
    $(TR $(TD ±0) $(TD any) $(TD ±0))
    $(TR $(TD any) $(TD 0) $(TD x))
)
*/
D ldexp(D)(auto const ref D x, const int n)
if (isDecimal!D)
{

    Unqual!D result = x;
    decimalScale(result, n, 
                        __ctfe ? D.PRECISION : DecimalControl.precision,
                        __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
    return result;
}

/**
Calculates the natural logarithm of log$(SUBSCRIPT e)x.
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN or x < 0))
    $(TR $(TD $(MYREF DivisionByZero)) 
         $(TD x is ±0.0))
    $(TR $(TD $(MYREF Underflow)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH log(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD -∞))
    $(TR $(TD -∞) $(TD NaN))
    $(TR $(TD +∞) $(TD +∞))
    $(TR $(TD e) $(TD +1.0))
    $(TR $(TD < 0.0) $(TD NaN))
)
*/
@IEEECompliant("log", 42)
D log(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalLog(result, 
                             __ctfe ? D.PRECISION : DecimalControl.precision, 
                             __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= (ExceptionFlags.inexact | ExceptionFlags.invalidOperation | ExceptionFlags.divisionByZero);
    DecimalControl.raiseFlags(flags);
    return result;
}

///
unittest
{
    assert (log(decimal32.E) == 1);
}


/**
Calculates log$(SUBSCRIPT 10)x.
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN or x < 0.0))
    $(TR $(TD $(MYREF DivisionByZero)) 
         $(TD x is ±0.0))
    $(TR $(TD $(MYREF Underflow)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH log(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD -∞))
    $(TR $(TD -∞) $(TD NaN))
    $(TR $(TD +∞) $(TD +∞))
    $(TR $(TD +10.0) $(TD +1.0))
    $(TR $(TD < 0.0) $(TD NaN))
)
*/
@IEEECompliant("log10", 42)
D log10(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalLog10(result, 
                            __ctfe ? D.PRECISION : DecimalControl.precision, 
                            __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= (ExceptionFlags.inexact | ExceptionFlags.invalidOperation | ExceptionFlags.divisionByZero);
    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Calculates log$(SUBSCRIPT 10)(x + 1).
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN or x < 1.0))
    $(TR $(TD $(MYREF DivisionByZero)) 
         $(TD x is -1.0))
    $(TR $(TD $(MYREF Underflow)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH log(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD -1.0) $(TD -∞))
    $(TR $(TD -∞) $(TD NaN))
    $(TR $(TD +∞) $(TD +∞))
    $(TR $(TD +9.0) $(TD +1.0))
    $(TR $(TD < -1.0) $(TD NaN))
)
*/
@IEEECompliant("log10p1", 42)
D log10p1(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalLog10p1(result, 
                              __ctfe ? D.PRECISION : DecimalControl.precision, 
                              __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= (ExceptionFlags.inexact | ExceptionFlags.invalidOperation | ExceptionFlags.divisionByZero);
    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Calculates log$(SUBSCRIPT 2)x.
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN or x < 0))
    $(TR $(TD $(MYREF DivisionByZero)) 
         $(TD x is ±0.0))
    $(TR $(TD $(MYREF Underflow)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH log(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD -∞))
    $(TR $(TD -∞) $(TD NaN))
    $(TR $(TD +∞) $(TD +∞))
    $(TR $(TD +2.0) $(TD +1.0))
    $(TR $(TD < 0.0) $(TD NaN))
)
*/
@IEEECompliant("log2", 42)
D log2(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalLog2(result, 
                              __ctfe ? D.PRECISION : DecimalControl.precision, 
                              __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= (ExceptionFlags.inexact | ExceptionFlags.invalidOperation | ExceptionFlags.divisionByZero);
    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Calculates log$(SUBSCRIPT 2)(x + 1).
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN or x < 0))
    $(TR $(TD $(MYREF DivisionByZero)) 
         $(TD x is -1.0))
    $(TR $(TD $(MYREF Underflow)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH log(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD -∞))
    $(TR $(TD -∞) $(TD NaN))
    $(TR $(TD +∞) $(TD +∞))
    $(TR $(TD +1.0) $(TD +1.0))
    $(TR $(TD < -1.0) $(TD NaN))
)
*/
@IEEECompliant("log2p1", 42)
D log2p1(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalLog2p1(result, 
                             __ctfe ? D.PRECISION : DecimalControl.precision, 
                             __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= (ExceptionFlags.inexact | ExceptionFlags.invalidOperation | ExceptionFlags.divisionByZero);
    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Calculates log$(SUBSCRIPT e)(x + 1).
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN or x < 0))
    $(TR $(TD $(MYREF DivisionByZero)) 
         $(TD x is -1.0))
    $(TR $(TD $(MYREF Underflow)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH log(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD -∞))
    $(TR $(TD -∞) $(TD NaN))
    $(TR $(TD +∞) $(TD +∞))
    $(TR $(TD e - 1) $(TD +1.0))
    $(TR $(TD < -1.0) $(TD NaN))
)
*/
@IEEECompliant("logp1", 42)
D logp1(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalLogp1(result, 
                               __ctfe ? D.PRECISION : DecimalControl.precision, 
                               __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    flags &= (ExceptionFlags.inexact | ExceptionFlags.invalidOperation | ExceptionFlags.divisionByZero);
    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Returns the value of x rounded using the specified rounding _mode.
If no rounding _mode is specified the default context rounding _mode is used instead.
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is NaN or ±∞))
   $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH lrint(x)))
    $(TR $(TD NaN) $(TD 0))
    $(TR $(TD -∞) $(TD long.min))
    $(TR $(TD +∞) $(TD long.max))
)
*/
long lrint(D)(auto const ref D x, const RoundingMode mode)
{
    long result;
    if (isNaN(x))
        flags = ExceptionFlags.invalidOperation;
    else if (isInfinity(x))
    {
        flags = ExceptionFlags.invalidOperation;
        result = signbit(x) ? long.min : long.max;
    }
    else
    {
        flags = decimalToSigned(x, result, mode);
        flags &= ExceptionFlags.invalidOperation | ExceptionFlags.overflow | ExceptionFlags.inexact;
    }

    DecimalControl.raiseFlags(flags);
    return result;
}

///ditto
long lrint(D)(auto const ref D x)
{
    return lrint(x, __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
}

/**
Returns the value of x rounded away from zero.
Throws:
    $(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is NaN or ±∞))
   $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH lround(x)))
    $(TR $(TD NaN) $(TD 0))
    $(TR $(TD -∞) $(TD long.min))
    $(TR $(TD +∞) $(TD long.max))
)
*/
long lround(D)(auto const ref D x)
{
    long result;
    if (isNaN(x))
        flags = ExceptionFlags.invalidOperation;
    else if (isInfinity(x))
    {
        flags = ExceptionFlags.invalidOperation;
        result = signbit(x) ? long.min : long.max;
    }
    else
    {
        flags = decimalToSigned(x, result, RoundingMode.tiesToAway);
        flags &= ExceptionFlags.invalidOperation | ExceptionFlags.overflow;
    }

    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Splits x in integral and fractional part. This operation is silent, doesn't throw any exception
Params:
    x = value to split
    y = fractional part
Returns:
    The value of x truncated toward zero. 
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH modf(x)) $(TH y))
    $(TR $(TD NaN) $(TD NaN) $(TD NaN))
    $(TR $(TD 0.0) $(TD 0.0) $(TD 0.0))
    $(TR $(TD ±∞) $(TD 0.0) $(TD ±∞))
)
*/
D modf(D)(auto const ref D x, ref D y)
if (isDecimal!D)
{
    if (isNaN(x))
    {
        y = D.nan;
        return D.nan;
    }
    else if (isZero(x))
    {
        y = canonical(x);
        return canonical(x);
    }
    else if (isInfinity(x))
    {
        y = canonical(x);
        return signbit(x) ? -D.zero : D.zero;
    }
    else
    {
        Unqual!D integral = x;
        decimalRound(x, RoundingMode.towardZero);
        decimalSub(y, x, integral, D.PRECISION, RoundingMode.tiesToAway);
        return integral;
    }
}

/**
Creates a quiet NaN value using the specified payload
Notes:
   Payloads are masked to fit the current representation, being limited to mant_dig - 2;
*/
@nogc nothrow pure @safe
decimal32 NaN(const uint payload)
{
    decimal32 result = void;
    result.data = decimal32.MASK_QNAN | (payload & decimal32.MASK_PAYL);
    return result;
}

///ditto
@nogc nothrow pure @safe
decimal64 NaN(const ulong payload)
{
    decimal64 result = void;
    result.data = decimal64.MASK_QNAN | (payload & decimal64.MASK_PAYL);
    return result;
}

///ditto
@nogc nothrow pure @safe
decimal128 NaN(const ulong payloadHi, const ulong payloadLo)
{
    decimal128 result = void;
    result.data = decimal128.MASK_QNAN | (uint128(payloadHi, payloadLo) & decimal128.MASK_PAYL);
    return result;
}

///
unittest
{
    decimal32 a = NaN(12345U);
    decimal64 b = NaN(12345UL);
    decimal128 c = NaN(123U, 456U);
}

/**
Returns the value of x rounded using the specified rounding _mode.
If no rounding _mode is specified the default context rounding _mode is used instead.
Throws:
    $(MYREF InvalidOperationException) if x is signaling NaN
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH nearbyint(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±∞) $(TD ±∞))
    $(TR $(TD ±0.0) $(TD ±0.0))
)
*/
@IEEECompliant("roundToIntegralTiesToAway", 19)
@IEEECompliant("roundToIntegralTiesToEven", 19)
@IEEECompliant("roundToIntegralTowardNegative", 19)
@IEEECompliant("roundToIntegralTowardPositive", 19)
@IEEECompliant("roundToIntegralTowardZero", 19)
D nearbyint(D)(auto const ref D x, const RoundingMode mode)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalRound(result, __ctfe ? D.PRECISION : DecimalControl.precision, mode);
    flags &= ExceptionFlags.invalidOperation;
    DecimalControl.raiseFlags(flags);
    return result;
}

///ditto
D nearbyint(D)(auto const ref D x)
if (isDecimal!D)
{
    return nearbyint(x, __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
}

///
unittest
{
    assert(nearbyint(decimal32("1.2"), RoundingMode.tiesToEven) == 1);
    assert(nearbyint(decimal64("2.7"), RoundingMode.tiesToAway) == 3);
    assert(nearbyint(decimal128("-7.9"), RoundingMode.towardZero) == -7);
    assert(nearbyint(decimal128("6.66")) == 7);
}


/**
Returns the previous _decimal value before x.
Throws:
    $(MYREF InvalidOperationException) if x is signaling NaN
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH nextDown(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD -∞) $(TD -∞))
    $(TR $(TD -max) $(TD -∞))
    $(TR $(TD ±0.0) $(TD -min_normal * epsilon))
    $(TR $(TD +∞) $(TD D.max))
)
*/
@IEEECompliant("nextDown", 19)
D nextDown(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalNextDown(result) & ExceptionFlags.invalidOperation;
    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Gives the next power of 10 after x. 
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH nextPow10(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±∞) $(TD ±∞))
    $(TR $(TD ±0.0) $(TD +1.0))
)
*/
D nextPow10(D)(auto const ref D x)
if (isDecimal!D)
{
    ExceptionFlags flags;
    Unqual!D result;

    if (isSignaling(x))
    {
        result = D.nan;
        flags = ExceptionFlags.invalidOperation;
    }
    else if (isNaN(x) || isInfinity(x))
        result = x;
    else if (isZero(x))
        result = D.one;
    else
    {
        alias U = DataType!D;
        U c;
        int e;
        bool s = x.unpack(c, e);
        for (size_t i = 0; i < pow10!U.length; ++i)
        {
            if (c == pow10!U[i])
            {
                ++e;
                break;
            }
            else if (c < pow10!U[i])
            {
                c = pow10!U[i];
                break;
            }
        }
        if (i == pow10!U.length)
        {
            c = pow10!U[$ - 1];
            ++e;
        }
        
        flags = result.adjustedPack(c, e, s, RoundingMode.towardZero, ExceptionFlags.none);
    }

    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Returns the next representable _decimal value after x.
Throws:
    $(MYREF InvalidOperationException) if x is signaling NaN
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH nextUp(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD -∞) $(TD -D.max))
    $(TR $(TD ±0.0) $(TD D.min_normal * epsilon))
    $(TR $(TD D.max) $(TD +∞))
    $(TR $(TD +∞) $(TD +∞))
)
*/
@IEEECompliant("nextUp", 19)
D nextUp(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalNextUp(result) & ExceptionFlags.invalidOperation;
    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Calculates a$(SUBSCRIPT 0) + a$(SUBSCRIPT 1)x + a$(SUBSCRIPT 2)x$(SUPERSCRIPT 2) + .. + a$(SUBSCRIPT n)x$(SUPERSCRIPT n)
Throws:
    $(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN or any a$(SUBSCRIPT i) is signaling NaN))
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is ±∞ and any a$(SUBSCRIPT i) is ±0.0))
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is ±0.0 and any a$(SUBSCRIPT i) is ±∞))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD result is inexact))
)
*/
auto poly(D1, D2)(auto const ref D1 x, const(D2)[] a)
if (isDecimal!(D1, D2))
{
    ExceptionFlags flags;
    alias D = CommonDecimal!(D1, D2);
    D result;
    auto flags = decimalPoly(x, a, result, 
                            __ctfe ? D.PRECISION : DecimalControl.precision,
                            __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Compute the value of x$(SUPERSCRIPT n), where n is integral
Throws:
    $(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN))
    $(TR $(TD $(MYREF DivisionByZeroException)) 
         $(TD x = ±0.0 and n < 0))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH n) $(TH pow(x, n)) )
    $(TR $(TD sNaN) $(TD any) $(TD NaN) )
    $(TR $(TD any) $(TD 0) $(TD +1.0) )
    $(TR $(TD NaN) $(TD any) $(TD NaN))
    $(TR $(TD ±∞) $(TD any) $(TD ±∞) )
    $(TR $(TD ±0.0) $(TD odd n < 0) $(TD ±∞))
    $(TR $(TD ±0.0) $(TD even n < 0) $(TD +∞) )
    $(TR $(TD ±0.0) $(TD odd n > 0) $(TD ±0.0)  )
    $(TR $(TD ±0.0) $(TD even n > 0) $(TD +0.0) )
)
*/
@IEEECompliant("pown", 42)
D pow(D, T)(auto const ref D x, const T n)
if (isDecimal!D && isIntegral!T)
{
    ExceptionFlags flags;
    Unqual!D result = x;
    auto flags = decimalPow(result, n, 
                           __ctfe ? D.PRECISION : DecimalControl.precision,
                           __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Compute the value of x$(SUPERSCRIPT y)
Throws:
    $(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN))
    $(TR $(TD $(MYREF DivisionByZeroException)) 
         $(TD x = ±0.0 and y < 0.0))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH y) $(TH pow(x, y)) )
    $(TR $(TD sNaN) $(TD any) $(TD NaN) )
    $(TR $(TD any) $(TD 0) $(TD +1.0) )
    $(TR $(TD NaN) $(TD any) $(TD NaN))
    $(TR $(TD ±∞) $(TD any) $(TD ±∞) )
    $(TR $(TD ±0.0) $(TD odd n < 0) $(TD ±∞))
    $(TR $(TD ±0.0) $(TD even n < 0) $(TD +∞) )
    $(TR $(TD ±0.0) $(TD odd n > 0) $(TD ±0.0)  )
    $(TR $(TD ±0.0) $(TD even n > 0) $(TD +0.0) )
)
*/
@IEEECompliant("pow", 42)
@IEEECompliant("powr", 42)
auto pow(D1, D2)(auto const ref D1 x, auto const ref D2 x)
{
    ExceptionFlags flags;
    Unqual!D1 result = x;
    auto flags = decimalPow(result, y, 
                            __ctfe ? D.PRECISION : DecimalControl.precision,
                            __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
    DecimalControl.raiseFlags(flags);
    return result;
}




/**
Express a value using another value exponent
Params:
    x = source value
    y = value used as exponent source
Returns:
    a value with the same numerical value as x but with the exponent of y
Throws:
Throws:
    $(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN))
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD only one of x or y is ±∞))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH y) $(TH quantize(x, y)))
    $(TR $(TD NaN) $(TD any) $(TD NaN))
    $(TR $(TD any) $(TD NaN) $(TD NaN))
    $(TR $(TD ±∞) $(TD ±∞) $(TD ±∞))
    $(TR $(TD ±∞) $(TD any) $(TD NaN))
    $(TR $(TD any) $(TD ±∞) $(TD NaN))
)
*/
@IEEECompliant("quantize", 18)
D1 quantize(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!(D1, D2))
{
    D1 result = x;
    auto flags = decimalQuantize(result, y, 
                                 __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
    flags &= ExceptionFlags.invalidOperation | ExceptionFlags.inexact; 
    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Calculates the _remainder of the division x / y
Params:
    x = dividend
    y = divisor
Returns:
    The value of x - n * y, where n is the quotient rounded to nearest even of the division x / y  
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x or y is signaling NaN, x = ±∞, y = ±0.0))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF DivisionByZeroException)) 
         $(TD y = 0.0))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH y) $(TH remainder(x, y)))
    $(TR $(TD NaN) $(TD any) $(TD NaN))
    $(TR $(TD any) $(TD NaN) $(TD NaN))
    $(TR $(TD ±∞) $(TD any) $(TD NaN))
    $(TR $(TD any) $(TD 0.0) $(TD NaN))
    $(TR $(TD any) $(TD ±∞) $(TD NaN))
)
*/
@IEEECompliant("remainder", 25)
auto remainder(D1, D2)(auto const ref D1 x, auto const ref D2 y)
{
    CommonDecimal!(D1, D2) result;
    auto flags = decimalMod(result, x, y, 
                            __ctfe ? D.PRECISION : DecimalControl.precision,
                            RoundingMode.tiesToEven);
    DecimalControl.raiseFlags(flags);
    return result;
}



/**
Returns the value of x rounded using the specified rounding _mode.
If no rounding _mode is specified the default context rounding _mode is used instead.
This function is similar to $(MYREF nearbyint), but if the rounded value is not exact it will throw
$(MYREF InexactException)
Throws:
    $(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH rint(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±∞) $(TD ±∞))
    $(TR $(TD ±0.0) $(TD ±0.0))
)
*/
@IEEECompliant("roundToIntegralExact", 25)
D rint(D)(auto const ref D x, const RoundingMode mode)
if (isDecimal!D)
{
    Unqual!D result = canonical(x);
    auto flags = decimalRound(result, __ctfe ? D.PRECISION : DecimalControl.precision, mode);
    flags &= ExceptionFlags.invalidOperation | ExceptionFlags.inexact;
    DecimalControl.raiseFlags(flags);
    return result;
}

///ditto
@IEEECompliant("roundToIntegralExact", 25)
D rint(D)(auto const ref D x)
if (isDecimal!D)
{
    return rint(x, __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
}

///
unittest
{
    DecimalControl.resetFlags(ExceptionFlags.inexact);
    assert(rint(decimal32("9.9")) == 10);
    assert(DecimalControl.inexact);

    DecimalControl.resetFlags(ExceptionFlags.inexact);
    assert(rint(decimal32("9.0")) == 9);
    assert(!DecimalControl.inexact);
}

/**
Returns the value of x rounded using the specified rounding _mode.
If no rounding _mode is specified the default context rounding _mode is used instead.
If the value doesn't fit in a long data type $(MYREF OverflowException) is thrown.
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is NaN))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result does not fit in a long data type))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH rndtonl(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±∞) $(TD ±∞))
    $(TR $(TD ±0.0) $(TD ±0.0))
)
*/
D rndtonl(D)(auto const ref D x, const RoundingMode mode)
{
    Unqual!D result = canonical(x);
    long l;
    if (isNaN(x))
    {
        flags = ExceptionFlags.invalidOperation;
        result = signbit(x) ? -D.nan : D.nan;
    }
    else if (isInfinity(x))
        flags = ExceptionFlags.overflow;
    else 
    {
        flags = decimalToUnsigned(x, l, mode);
        result.packIntegral(l, 0, mode);
    }
    DecimalControl.raiseFlags(flags);
    return result;
}

///ditto
@safe
D rndtonl(D)(auto const ref D x)
{
    return rndtonl(x, __ctfe ? RoundingMode.tiesToAway : DecimalControl.rounding);
}

/**
Compute the value of x$(SUPERSCRIPT 1/n), where n is an integer
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN))
    $(TR $(TD $(MYREF DivisionByZeroException)) 
         $(TD x = ±0.0 and n < 0.0))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented or n = -1))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented or n = -1))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH y) $(TH root(x, n)) )
    $(TR $(TD sNaN) $(TD any) $(TD NaN) )
    $(TR $(TD any) $(TD 0) $(TD NaN) )
    $(TR $(TD any) $(TD -1) $(TD NaN) )
    $(TR $(TD NaN) $(TD any) $(TD NaN))
    $(TR $(TD ±∞) $(TD any) $(TD ±∞) )
    $(TR $(TD ±0.0) $(TD odd n < 0) $(TD ±∞))
    $(TR $(TD ±0.0) $(TD even n < 0) $(TD +∞) )
    $(TR $(TD ±0.0) $(TD odd n > 0) $(TD ±0.0)  )
    $(TR $(TD ±0.0) $(TD even n > 0) $(TD +0.0) )
)
*/
@IEEECompliant("rootn", 42)
D root(D)(auto const ref D x, const T n)
if (isDecimal!D & isIntegral!T)
{
    ExceptionFlags flags;
    Unqual!D1 result = x;
    auto flags = decimalRoot(result, n, 
                            __ctfe ? D.PRECISION : DecimalControl.precision,
                            __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Returns the value of x rounded away from zero.
This operation is silent, doesn't throw any exception.
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH round(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±0.0) $(TD ±0.0))
    $(TR $(TD ±∞) $(TD ±∞))
)
*/
D round(D)(auto const ref D x)
{
    auto result = canonical(x);
    if (isNaN(x) || isInfinity(x) || isZero(x))
        return result;
    decimalRound(result, RoundingMode.tiesToAway);
    return result;
}

/**
Computes the inverse square root of x
Throws:
    $(MYREF InvalidOperationException) if x is signaling NaN or negative,
    $(MYREF InexactException), $(MYREF UnderflowException),
    $(MYREF DivisionByZeroException)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH rsqrt(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD < 0.0) $(TD NaN))
    $(TR $(TD ±0.0) $(TD NaN))
    $(TR $(TD +∞) $(TD +∞))
)
*/
@IEEECompliant("rSqrt", 42)
D rsqrt(D)(auto const ref D x)
if (isDecimal!D)
{
    ExceptionFlags flags;

    Unqual!D result = x;

    flags = decimalRSqrt(result, 
                            __ctfe ? D.PRECISION : DecimalControl.precision, 
                            __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Compares the exponents of two _decimal values
Params:
    x = a _decimal value
    y = a _decimal value
Returns:
    true if the internal representation of x and y use the same exponent, false otherwise
Notes:
    Returns also true if both operands are NaN or both operands are infinite.
*/
@IEEECompliant("sameQuantum", 26)
bool sameQuantum(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!(D1, D2))
{
    if ((x.data & D1.MASK_INF) == D1.MASK_INF)
    {
        if ((x.data & D1.MASK_QNAN) == D1.MASK_QNAN)
            return (y.data & D2.MASK_QNAN) == D2.MASK_QNAN;
        return (y.data & D2.MASK_SNAN) == D2.MASK_INF;
    }

    if ((y.data & D2.MASK_INF) == D2.MASK_INF)
        return false;

    auto expx = (x.data & D1.MASK_EXT) == D1.MASK_EXT ?
        (x.data & D1.MASK_EXP2) >>> D1.SHIFT_EXP2 :
        (x.data & D1.MASK_EXP1) >>> D1.SHIFT_EXP1;
    auto expy = (x.data & D2.MASK_EXT) == D2.MASK_EXT ?
        (y.data & D2.MASK_EXP2) >>> D2.SHIFT_EXP2 :
        (y.data & D2.MASK_EXP1) >>> D2.SHIFT_EXP1;
    return expx - D1.EXP_BIAS == expy - D2.EXP_BIAS;
}

///
unittest
{
    assert(sameQuantum(decimal32.infinity, -decimal64.infinity));

    auto x = decimal32("123456e+23");
    auto y = decimal64("911911e+23");
    assert(sameQuantum(x, y));

}

/**
Returns:
    x efficiently multiplied by 10$(SUPERSCRIPT n)
Throws:
    $(MYREF InvalidOperationException) if x is signaling NaN, $(MYREF OverflowException), 
    $(MYREF UnderflowException), $(MYREF InexactException)   
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH n) $(TH scalbn(x, n)))
    $(TR $(TD NaN) $(TD any) $(TD NaN))
    $(TR $(TD ±∞) $(TD any) $(TD ±∞))
    $(TR $(TD ±0) $(TD any) $(TD ±0))
    $(TR $(TD any) $(TD 0) $(TD x))
)
*/
@IEEECompliant("scaleB", 17)
D scalbn(D)(auto const ref D x, const int n)
if (isDecimal!D)
{
    Unqual!D result = x;
    flags = decimalScale(result, n, 
                            __ctfe ? D.PRECISION : DecimalControl.precision,
                            __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Multiplies elements of x using a higher precision, rounding only once at the end.
Returns:
    x$(SUBSCRIPT 0) * x$(SUBSCRIPT 1) * ... * x$(SUBSCRIPT n)
Notes:
    To avoid overflow, an additional scale is provided that the final result is to be multiplied py 10$(SUPERSCRIPT scale)
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD any x is signaling NaN))
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD there is one infinite element and one 0.0 element))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD result is inexact))
)
*/
@IEEECompliant("scaledProd", 47)
D scaledProd(D)(const(D)[] x, out int scale)
if (isDecimal!D)
{
    Unqual!D result;
    flags = decimalProd(x, result, scale, 
                         __ctfe ? D.PRECISION : DecimalControl.precision,
                         __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Multiplies results of x$(SUBSCRIPT i) + y$(SUBSCRIPT i) using a higher precision, rounding only once at the end.
Returns:
    (x$(SUBSCRIPT 0) + y$(SUBSCRIPT 0)) * (x$(SUBSCRIPT 1) + y$(SUBSCRIPT 1)) * ... * (x$(SUBSCRIPT n) + y$(SUBSCRIPT n))
Notes:
    To avoid overflow, an additional scale is provided that the final result is to be multiplied py 10$(SUPERSCRIPT scale).<br/>
    If x and y arrays are not of the same length, operation is performed for min(x.length, y.length);
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD any x is signaling NaN))
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD any x[i] and y[i] are infinite and with different sign))
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD there is one infinite element and one x$(SUBSCRIPT i) + y$(SUBSCRIPT i) == 0.0))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD result is inexact))
)
*/
@IEEECompliant("scaledProdSum", 47)
D scaledProdSum(D)(const(D)[] x, const(D)[] y, out int scale)
if (isDecimal!D)
{
    Unqual!D result;
    flags = decimalProdSum(x, y, result, scale, 
                        __ctfe ? D.PRECISION : DecimalControl.precision,
                        __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Multiplies results of x$(SUBSCRIPT i) - y$(SUBSCRIPT i) using a higher precision, rounding only once at the end.
Returns:
    (x$(SUBSCRIPT 0) - y$(SUBSCRIPT 0)) * (x$(SUBSCRIPT 1) - y$(SUBSCRIPT 1)) * ... * (x$(SUBSCRIPT n) - y$(SUBSCRIPT n))
Notes:
    To avoid overflow, an additional scale is provided that the final result is to be multiplied py 10$(SUPERSCRIPT scale)</br>
    If x and y arrays are not of the same length, operation is performed for min(x.length, y.length);
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD any x is signaling NaN))
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD any x$(SUBSCRIPT i) and y$(SUBSCRIPT i) are infinite and with different sign))
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD there is one infinite element and one x$(SUBSCRIPT i) - y$(SUBSCRIPT i) == 0.0))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD result is inexact))
)
*/
@IEEECompliant("scaledProdDiff", 47)
D scaledProdDiff(D)(const(D)[] x, const(D)[] y, out int scale)
if (isDecimal!D)
{
    Unqual!D result;
    flags = decimalProdDiff(x, y, result, scale, 
                           __ctfe ? D.PRECISION : DecimalControl.precision,
                           __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
    DecimalControl.raiseFlags(flags);
    return result;
}


/**
Determines if x is negative
This operation is silent, no error flags are set and no exceptions are thrown.
Params:
    x = a _decimal value
Returns: 
    -1.0 if x is negative, 0.0 if x is zero, 1.0 if x is positive
*/
@safe pure nothrow @nogc
D sgn(D)(auto const ref D x)
if (isDecimal!D)
{
    if (isZero(x))
        return D.zero;
    return (x.data & D.MASK_SGN) ? D.minusOne : D.one;
}

///
unittest
{
    assert(sgn(decimal32.max) == 1);
    assert(sgn(-decimal32.max) == -1);
    assert(sgn(decimal64(0)) == 0);
}

unittest
{

    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert(sgn(T.nan) == 1);
        assert(sgn(T.infinity) == 1);
        assert(sgn(T.minusInfinity) == -1);
    }
}

/**
Returns the sign bit of the specified value.
This operation is silent, no error flags are set and no exceptions are thrown.
Params:
    x = a _decimal value
Returns: 
    1 if the sign bit is set, 0 otherwise
*/
@IEEECompliant("isSignMinus", 25)
int signbit(D: Decimal!bits, int bits)(auto const ref D x)
{
    return cast(uint)((x.data & D.MASK_SGN) >>> ((D.sizeof * 8) - 1));
}

///
unittest
{
    assert(signbit(-decimal32.infinity) == 1);
    assert(signbit(decimal64.min_normal) == 0);
    assert(signbit(-decimal128.max) == 1);
}

unittest
{
    foreach(T; TypeTuple!(decimal32, decimal64, decimal128))
    {
        assert(signbit(T.snan) == 0);
        assert(signbit(T.minusInfinity) == 1);
        assert(signbit(T.zero) == 0);
        assert(signbit(T.minusZero) == 1);
    }
}

/**
Returns sine of x.
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN or ±∞))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH sin(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±∞) $(TD NaN))
    $(TR $(TD -π/2) $(TD -1.0))
    $(TR $(TD -π/3) $(TD -√3/2))
    $(TR $(TD -π/4) $(TD -√2/2))
    $(TR $(TD -π/6) $(TD -0.5))
    $(TR $(TD ±0.0) $(TD +0.0))
    $(TR $(TD +π/6) $(TD +0.5))
    $(TR $(TD +π/4) $(TD +√2/2))
    $(TR $(TD +π/3) $(TD +√3/2))
    $(TR $(TD +π/2) $(TD +1.0))
)
*/
@IEEECompliant("sin", 42)
D sin(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalSin(result, 
                             __ctfe ? D.PRECISION : DecimalControl.precision, 
                             __ctfe ? RoundingMode.implicit : DecimalControl.rounding);

    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Calculates the hyperbolic sine of x.
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH sinh(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±∞) $(TD +∞))
    $(TR $(TD ±0.0) $(TD +0.0))
)
*/
@IEEECompliant("sinh", 42)
D sinh(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalSinh(result, 
                            __ctfe ? D.PRECISION : DecimalControl.precision, 
                            __ctfe ? RoundingMode.implicit : DecimalControl.rounding);

    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Returns sine of x*π.
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN or ±∞))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH sin(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±∞) $(TD NaN))
    $(TR $(TD -1/2) $(TD -1.0))
    $(TR $(TD -1/3) $(TD -√3/2))
    $(TR $(TD -1/4) $(TD -√2/2))
    $(TR $(TD -1/6) $(TD -0.5))
    $(TR $(TD ±0.0) $(TD +0.0))
    $(TR $(TD +1/6) $(TD +0.5))
    $(TR $(TD +1/4) $(TD +√2/2))
    $(TR $(TD +1/3) $(TD +√3/2))
    $(TR $(TD +1/2) $(TD +1.0))
)
*/
@IEEECompliant("sinPi", 42)
D sinPi(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalSinPi(result, 
                             __ctfe ? D.PRECISION : DecimalControl.precision, 
                             __ctfe ? RoundingMode.implicit : DecimalControl.rounding);

    DecimalControl.raiseFlags(flags);
    return result;
}


/**
Computes the square root of x
Throws:
    $(MYREF InvalidOperationException) if x is signaling NaN or negative,
    $(MYREF InexactException), $(MYREF UnderflowException)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH sqrt(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD < 0.0) $(TD NaN))
    $(TR $(TD ±0.0) $(TD ±0.0))
    $(TR $(TD +∞) $(TD +∞))
)
*/
@IEEECompliant("squareRoot", 42)
D sqrt(D)(auto const ref D x)
if (isDecimal!D)
{

    Unqual!D result = x;
    auto flags = decimalSqrt(result, 
                        __ctfe ? D.PRECISION : DecimalControl.precision, 
                        __ctfe ? RoundingMode.implicit : DecimalControl.rounding);

    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Sums elements of x using a higher precision, rounding only once at the end.</br>
Returns:
    x$(SUBSCRIPT 0) + x$(SUBSCRIPT 1) + ... + x$(SUBSCRIPT n)
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD any x is signaling NaN))
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD there are two infinite elements with different sign))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD result is inexact))
)
*/
@IEEECompliant("sum", 47)
D sum(D)(const(D)[] x)
if (isDecimal!D)
{
    Unqual!D result;
    auto flags = decimalSum(x, result, 
                             __ctfe ? D.PRECISION : DecimalControl.precision, 
                             __ctfe ? RoundingMode.implicit : DecimalControl.rounding);

    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Sums absolute elements of x using a higher precision, rounding only once at the end.
Returns:
    |x$(SUBSCRIPT 0)| + |x$(SUBSCRIPT 1)| + ... + |x$(SUBSCRIPT n)|
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD any x is signaling NaN))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD result is inexact))
)
*/
@IEEECompliant("sumAbs", 47)
D sumAbs(D)(const(D)[] x)
if (isDecimal!D)
{
    Unqual!D result;
    auto flags = decimalSumAbs(x, result, 
                            __ctfe ? D.PRECISION : DecimalControl.precision, 
                            __ctfe ? RoundingMode.implicit : DecimalControl.rounding);

    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Sums squares of elements of x using a higher precision, rounding only once at the end.
Returns:
    x$(SUBSCRIPT 0)$(SUPERSCRIPT 2) + x$(SUBSCRIPT 1)$(SUPERSCRIPT 2) + ... + x$(SUBSCRIPT n)$(SUPERSCRIPT 2)
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD any x is signaling NaN))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD result is inexact))
)
*/
@IEEECompliant("sumSquare", 47)
D sumSquare(D)(const(D)[] x)
if (isDecimal!D)
{
    Unqual!D result;
    auto flags = decimalSumSquare(x, result, 
                            __ctfe ? D.PRECISION : DecimalControl.precision, 
                            __ctfe ? RoundingMode.implicit : DecimalControl.rounding);

    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Returns tangent of x.
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN or ±∞))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH tan(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±∞) $(TD NaN))
    $(TR $(TD -π/2) $(TD -∞))
    $(TR $(TD -π/3) $(TD -√3))
    $(TR $(TD -π/4) $(TD -1.0))
    $(TR $(TD -π/6) $(TD -1/√3))
    $(TR $(TD ±0.0) $(TD +0.0))
    $(TR $(TD +π/6) $(TD +1/√3))
    $(TR $(TD +π/4) $(TD +1.0))
    $(TR $(TD +π/3) $(TD +√3))
    $(TR $(TD +π/2) $(TD +∞))
)
*/
@IEEECompliant("tan", 42)
D tan(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalTan(result, 
                             __ctfe ? D.PRECISION : DecimalControl.precision, 
                             __ctfe ? RoundingMode.implicit : DecimalControl.rounding);

    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Returns tangent of x.
Throws:
$(BOOKTABLE,
    $(TR $(TD $(MYREF InvalidOperationException)) 
         $(TD x is signaling NaN ))
    $(TR $(TD $(MYREF UnderflowException)) 
         $(TD result is too small to be represented))
    $(TR $(TD $(MYREF OverflowException)) 
         $(TD result is too big to be represented))
    $(TR $(TD $(MYREF InexactException)) 
         $(TD the result is inexact))
)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH tanh(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±∞) $(TD ±1.0))
    $(TR $(TD ±0.0) $(TD ±0.0))
)
*/
@IEEECompliant("tanh", 42)
D tanh(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    auto flags = decimalTanh(result, 
                            __ctfe ? D.PRECISION : DecimalControl.precision, 
                            __ctfe ? RoundingMode.implicit : DecimalControl.rounding);

    DecimalControl.raiseFlags(flags);
    return result;
}


/**
Converts x to the specified integral type rounded if necessary by mode
Throws:
    $(MYREF InvalidOperationException) if x is NaN,
    $(MYREF UnderflowException), $(MYREF OverflowException)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH to!T(x)))
    $(TR $(TD NaN) $(TD 0))
    $(TR $(TD +∞) $(TD T.max))
    $(TR $(TD -∞) $(TD T.min))
    $(TR $(TD ±0.0) $(TD 0))
)
*/
@IEEECompliant("convertToIntegerTiesToAway", 22)
@IEEECompliant("convertToIntegerTiesToEven", 22)
@IEEECompliant("convertToIntegerTowardNegative", 22)
@IEEECompliant("convertToIntegerTowardPositive", 22)
@IEEECompliant("convertToIntegerTowardZero", 22)
T to(T, D)(auto const ref D x, const RoundingMode mode)
if (isIntegral!T && isDecimal!D)
{
    Unqual!T result;
    static if (isUnsigned!T)
        auto flags = decimalToUnsigned(x, result, mode);
    else
        auto flags = decimalToSigned(x, result, mode);
    DecimalControl.raiseFlags(flags & ~ExceptionFlags.inexact);
    return result;
}


/**
Converts x to the specified binary floating point type rounded if necessary by mode
Throws:
    $(MYREF UnderflowException), $(MYREF OverflowException)
*/
F to(F, D)(auto const ref D x, const RoundingMode mode)
if (isFloatingPoint!F && isDecimal!D)
{
    Unqual!F result;
    flags = decimalToFloat(x, result, mode);
    flags &= ~ExceptionFlags.inexact;
    if (__ctfe)
        DecimalControl.checkFlags(flags, ExceptionFlags.severe);
    else
    {
        if (flags)
            DecimalControl.raiseFlags(flags);
    }
    return result;
}

/**
Converts the specified value from internal encoding from/to densely packed decimal encoding
Notes:
   _Decimal values are represented internaly using 
   $(LINK2 https://en.wikipedia.org/wiki/Binary_Integer_Decimal, binary integer _decimal encoding), 
   supported by Intel (BID).
   This function converts the specified value to/from 
   $(LINK2 https://en.wikipedia.org/wiki/Densely_Packed_Decimal, densely packed _decimal encoding), 
   supported by IBM (DPD).
   Please note that a DPD encoded _decimal cannot be passed to a function from this module, there is no way
   to determine if a _decimal value is BID-encoded or DPD-encoded, all functions will assume a BID-encoding.
*/
@IEEECompliant("encodeDecimal", 23)
@safe pure nothrow @nogc
decimal32 toDPD(const decimal32 x) 
{
    if (isNaN(x) || isInfinity(x) || isZero(x))
        return canonical(x);

    uint cx;
    int ex;
    bool sx = x.unpack(cx, ex);

    uint[7] digits;
    size_t index = digits.length;
    while (cx)
        digits[--index] = divrem(cx, 10U);
    
    cx = packDPD(digits[$ - 3], digits[$ - 2], digits[$ - 1]);
    cx |= packDPD(digits[$ - 6], digits[$ - 5], digits[$ - 4]) << 10;
    cx |= cast(uint)digits[0] << 20;

    decimal32 result;
    result.pack(cx, ex, sx, true); 
    return result;
}

///ditto
@IEEECompliant("encodeDecimal", 23)
@safe pure nothrow @nogc
decimal64 toDPD(const decimal64 x) 
{
    if (isNaN(x) || isInfinity(x) || isZero(x))
        return canonical(x);

    ulong cx;
    int ex;
    bool sx = x.unpack(cx, ex);

    uint[16] digits;
    size_t index = digits.length;
    while (cx)
        digits[--index] = cast(uint)(divrem(cx, 10U));

    cx = cast(ulong)(packDPD(digits[$ - 3], digits[$ - 2], digits[$ - 1]));
    cx |= cast(ulong)packDPD(digits[$ - 6], digits[$ - 5], digits[$ - 4]) << 10;
    cx |= cast(ulong)packDPD(digits[$ - 9], digits[$ - 8], digits[$ - 7]) << 20;
    cx |= cast(ulong)packDPD(digits[$ - 12], digits[$ - 11], digits[$ - 10]) << 30;
    cx |= cast(ulong)packDPD(digits[$ - 15], digits[$ - 14], digits[$ - 13]) << 40;
    cx |= cast(ulong)digits[0] << 50;

    decimal64 result;
    result.pack(cx, ex, sx, true); 
    return result;
}

///ditto
@IEEECompliant("encodeDecimal", 23)
@safe pure nothrow @nogc
decimal128 toDPD(const decimal128 x) 
{
    if (isNaN(x) || isInfinity(x) || isZero(x))
        return canonical(x);

    uint128 cx;
    int ex;
    bool sx = x.unpack(cx, ex);

    uint[34] digits;
    size_t index = digits.length;
    while (cx)
        digits[--index] = cast(uint)(divrem(cx, 10U));

    cx = uint128(packDPD(digits[$ - 3], digits[$ - 2], digits[$ - 1]));
    cx |= uint128(packDPD(digits[$ - 6], digits[$ - 5], digits[$ - 4])) << 10;
    cx |= uint128(packDPD(digits[$ - 9], digits[$ - 8], digits[$ - 7])) << 20;
    cx |= uint128(packDPD(digits[$ - 12], digits[$ - 11], digits[$ - 10])) << 30;
    cx |= uint128(packDPD(digits[$ - 15], digits[$ - 14], digits[$ - 13])) << 40;
    cx |= uint128(packDPD(digits[$ - 18], digits[$ - 17], digits[$ - 16])) << 50;
    cx |= uint128(packDPD(digits[$ - 21], digits[$ - 20], digits[$ - 19])) << 60;
    cx |= uint128(packDPD(digits[$ - 24], digits[$ - 23], digits[$ - 22])) << 70;
    cx |= uint128(packDPD(digits[$ - 27], digits[$ - 26], digits[$ - 25])) << 80;
    cx |= uint128(packDPD(digits[$ - 30], digits[$ - 29], digits[$ - 28])) << 90;
    cx |= uint128(packDPD(digits[$ - 33], digits[$ - 32], digits[$ - 31])) << 100;
    cx |= uint128(digits[0]) << 110;

    decimal128 result;
    result.pack(cx, ex, sx, true); 
    return result;
}

///ditto
@IEEECompliant("decodeDecimal", 23)
@safe pure nothrow @nogc
decimal32 fromDPD(const decimal32 x) 
{
    if (isNaN(x) || isInfinity(x) || isZero(x))
        return canonical(x);

    uint[7] digits;
    uint cx;
    int ex;
    bool sx = x.unpack(cx, ex);

    unpackDPD(cx & 1023, digits[$ - 1], digits[$ - 2], digits[$ - 3]);
    unpackDPD((cx >>> 10) & 1023, digits[$ - 4], digits[$ - 5], digits[$ - 6]);
    digits[0] = (cx >>> 20) & 15;

    cx = 0U;
    for (size_t i = 0; i < digits.length; ++i)
        cx += digits[i] * pow10!uint[6 - i];

    decimal32 result;
    result.pack(cx, ex, sx, true); 
    return result;
}

///ditto
@IEEECompliant("decodeDecimal", 23)
@safe pure nothrow @nogc
decimal64 fromDPD(const decimal64 x) 
{
    if (isNaN(x) || isInfinity(x) || isZero(x))
        return canonical(x);

    uint[16] digits;
    ulong cx;
    int ex;
    bool sx = x.unpack(cx, ex);

    unpackDPD(cast(uint)cx & 1023, digits[$ - 1], digits[$ - 2], digits[$ - 3]);
    unpackDPD(cast(uint)(cx >>> 10) & 1023, digits[$ - 4], digits[$ - 5], digits[$ - 6]);
    unpackDPD(cast(uint)(cx >>> 20) & 1023, digits[$ - 7], digits[$ - 8], digits[$ - 9]);
    unpackDPD(cast(uint)(cx >>> 30) & 1023, digits[$ - 10], digits[$ - 11], digits[$ - 12]);
    unpackDPD(cast(uint)(cx >>> 40) & 1023, digits[$ - 13], digits[$ - 14], digits[$ - 15]);
    digits[0] = cast(uint)(cx >>> 50) & 15;

    cx = 0U;
    for (size_t i = 0; i < digits.length; ++i)
        cx += digits[i] * pow10!ulong[15 - i];

    decimal64 result;
    result.pack(cx, ex, sx, true); 
    return result;
}

///ditto
@safe pure nothrow @nogc
@IEEECompliant("decodeDecimal", 23)
decimal128 fromDPD(const decimal128 x) 
{
    if (isNaN(x) || isInfinity(x) || isZero(x))
        return canonical(x);

    uint[34] digits;
    uint128 cx;
    int ex;
    bool sx = x.unpack(cx, ex);

    unpackDPD(cast(uint)cx & 1023U, digits[$ - 1], digits[$ - 2], digits[$ - 3]);
    unpackDPD(cast(uint)(cx >>> 10) & 1023, digits[$ - 4], digits[$ - 5], digits[$ - 6]);
    unpackDPD(cast(uint)(cx >>> 20) & 1023, digits[$ - 7], digits[$ - 8], digits[$ - 9]);
    unpackDPD(cast(uint)(cx >>> 30) & 1023, digits[$ - 10], digits[$ - 11], digits[$ - 12]);
    unpackDPD(cast(uint)(cx >>> 40) & 1023, digits[$ - 13], digits[$ - 14], digits[$ - 15]);
    unpackDPD(cast(uint)(cx >>> 50) & 1023, digits[$ - 16], digits[$ - 17], digits[$ - 18]);
    unpackDPD(cast(uint)(cx >>> 60) & 1023, digits[$ - 19], digits[$ - 20], digits[$ - 21]);
    unpackDPD(cast(uint)(cx >>> 70) & 1023, digits[$ - 22], digits[$ - 23], digits[$ - 24]);
    unpackDPD(cast(uint)(cx >>> 80) & 1023, digits[$ - 25], digits[$ - 26], digits[$ - 27]);
    unpackDPD(cast(uint)(cx >>> 90) & 1023, digits[$ - 28], digits[$ - 29], digits[$ - 30]);
    unpackDPD(cast(uint)(cx >>> 100) & 1023, digits[$ - 31], digits[$ - 32], digits[$ - 33]);
    digits[0] = cast(uint)(cx >>> 110) & 15;

    cx = 0U;
    for (size_t i = 0; i < digits.length; ++i)
        cx += pow10!uint128[34 - i] * digits[i];

    decimal128 result;
    result.pack(cx, ex, sx, true); 
    return result;
}

/**
Converts x to the specified integral type rounded if necessary by mode
Throws:
$(MYREF InvalidOperationException) if x is NaN,
$(MYREF InexactException)
$(MYREF UnderflowException), $(MYREF OverflowException)
Special_values:
$(BOOKTABLE,
$(TR $(TH x) $(TH toExact!T(x)))
$(TR $(TD NaN) $(TD 0))
$(TR $(TD +∞) $(TD T.max))
$(TR $(TD -∞) $(TD T.min))
$(TR $(TD ±0.0) $(TD 0))
)
*/
@IEEECompliant("convertToIntegerExactTiesToAway", 22)
@IEEECompliant("convertToIntegerExactTiesToEven", 22)
@IEEECompliant("convertToIntegerExactTowardNegative", 22)
@IEEECompliant("convertToIntegerExactTowardPositive", 22)
@IEEECompliant("convertToIntegerExactTowardZero", 22)
T toExact(T, D)(auto const ref D x, const RoundingMode mode)
if (isIntegral!T && isDecimal!D)
{
    Unqual!T result;
    static if (isUnsigned!T)
        auto flags = decimalToUnsigned(x, result, mode);
    else
        auto flags = decimalToSigned(x, result, mode);
    DecimalControl.raiseFlags(flags);
    return result;
}

/**
Converts x to the specified binary floating point type rounded if necessary by mode
Throws:
    $(MYREF UnderflowException), $(MYREF OverflowException),
    $(MYREF InexactException)
*/
F toExact(F, D)(auto const ref D x, const RoundingMode mode)
if (isFloatingPoint!F && isDecimal!D)
{
    Unqual!F result;
    flags = decimalToFloat(x, result, mode);
    flags &= ~ExceptionFlags.inexact;
    if (__ctfe)
        DecimalControl.checkFlags(flags, ExceptionFlags.severe);
    else
    {
        if (flags)
            DecimalControl.raiseFlags(flags);
    }
    return result;
}

/**
Converts the specified value to/from Microsoft currency data type;
Throws:
    $(MYREF InvalidOperationException), $(MYREF InexactException)
    $(MYREF UnderflowException), $(MYREF OverflowException)
Notes:
    The Microsoft currency data type is stored as long 
    always scaled by 10$(SUPERSCRIPT -4)
*/
long toMsCurrency(D)(auto const ref D x)
if (isDecimal!D)
{
    ExceptionFlags flags;

    if (isNaN(x))
    {
        DecimalControl.raiseFlags(ExceptionFlags.invalidOperation);
        return 0;
    }

    if (isInfinity(x))
    {
        DecimalControl.raiseFlags(ExceptionFlags.overflow);
        return signbit(x) ? long.max : long.min;
    }

    if (isZero(x))
        return 0;

    ex +=2;

    long result;
    flags = decimalToSigned!long(x, result, 
                                 __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
    DecimalControl.raiseFlags(flags);
    return result;
}

///ditto
D fromMsCurrency(D)(const ulong x)
if (isDecimal!D)
{
    ExceptionFlags flags;
    Unqual!D result;
    flags = result.packIntegral(result, D.PRECISION, RoundingMode.implicit);
    flags |= decimalDiv(result, 100, 
                        __ctfe ? D.PRECISION : DecimalControl.precision, 
                        __ctfe ? RoundingMode.implicit : DecimalControl.rounding);
    DecimalControl.raiseFlags(flags);
    return result;
}

version(Windows)
{

    /**
    Converts the specified value to/from Microsoft _decimal data type;
    Throws:
        $(MYREF InvalidOperationException), $(MYREF InexactException)
        $(MYREF UnderflowException), $(MYREF OverflowException)
    Notes:
        The Microsoft _decimal data type is stored as a 96 bit integral 
        scaled by a variable exponent between 10$(SUPERSCRIPT -28) and 10$(SUPERSCRIPT 0). 
    Availability:
        This conversion function is available only on Windows systems
    */
    DECIMAL toMsDecimal(D)(auto const ref D x)
    {
        ExceptionFlags flags;
        DECIMAL result;

        if (isNaN(x))
        {
            if (__ctfe)
                DecimalControl.checkFlags(ExceptionFlags.invalidOperation, ExceptionFlags.severe);
            else
            {
                DecimalControl.raiseFlags(ExceptionFlags.invalidOperation);
            }
            return result;
        }

        if (isInfinity(x))
        {
            if (__ctfe)
                DecimalControl.checkFlags(ExceptionFlags.overflow, ExceptionFlags.severe);
            else
            {
                DecimalControl.raiseFlags(ExceptionFlags.overflow);
            }
            result.Lo64 = ulong.max;
            result.Hi32 = uint.max;
            if (signbit(x))
                result.sign = DECIMAL.DECIMAL_NEG;
            return result;
        }

        if (isZero(x))
            return result;

        DataType!D cx;
        int ex;
        bool sx = x.unpack(cx, ex);

        
        static if (is(D == decimal128))
            alias cxx = cx;
        else
            uint128 cxx = cx;

        enum cmax = uint128(cast(ulong)(uint.max), ulong.max);

        flags = adjustCoefficient(cxx, ex, -28, 0, cmax, sx, 
                                    __ctfe ? RoundingMode.implicit : DecimalControl.rounding);

        if (flags & ExceptionFlags.overflow)
        {
            result.Lo64 = ulong.max;
            result.Hi32 = uint.max;
            if (signbit(x))
                result.sign = DECIMAL.DECIMAL_NEG;
        }
        else if (flags & ExceptionFlags.underflow)
        {
            result.Lo64 = 0;
            result.Hi32 = 0;
            if (sx)
                result.sign = DECIMAL.DECIMAL_NEG;
        }
        else
        {
            result.Lo64 = cxx.lo;
            result.Hi32 = cast(uint)(cxx.hi);
            result.scale = -ex;
            if (sx)
                result.sign = DECIMAL.DECIMAL_NEG;
        }
        
        DecimalControl.raiseFlags(flags);
        return result;
    }


    ///ditto
    D fromMsDecimal(D)(auto const ref DECIMAL x)
    {
        ExceptionFlags flags;
        Unqual!D result;

        uint128 cx = uint128(cast(ulong)(x.Hi32), x.Lo64);
        int ex = -x.scale;
        bool sx = (x.sign & DECIMAL.DECIMAL_NEG) == DECIMAL.DECIMAL_NEG; 
        
        flags = coefficientAdjust(cx, ex, cvt!uint128(D.COEF_MAX), RoundingMode.implicit);

        flags |= result.adjustedPack(cvt!(DataType!D)(cx), ex, sx,
                                     __ctfe ?  D.PRECISION : DecimalControl.precision,
                                     __ctfe ? RoundingMode.implicit  : DecimalControl.rounding,
                                     flags);
        DecimalControl.raiseFlags(flags);
        return result;
    }
}


/**
Checks the order between two _decimal values
Params:
    x = a _decimal value
    y = a _decimal value
Returns:
    true if x precedes y, false otherwise
Notes:
    totalOrderAbs checks the order between |x| and |y|
See_Also:
    $(MYREF cmp)
*/
@IEEECompliant("totalOrder", 25)
bool totalOrder(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!(D1, D2))
{
    return cmp(x, y) < 0;
}

///ditto
@IEEECompliant("totalOrderAbs", 25)
bool totalOrderAbs(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!(D1, D2))
{
    return cmp(abs(x), abs(y)) < 0;
}

///
unittest
{
    assert (totalOrder(decimal32.min_normal, decimal64.max));
    assert (!totalOrder(decimal32.max, decimal128.min_normal));
    assert (totalOrder(-decimal64(0), decimal64(0)));
    assert (!totalOrderAbs(-decimal64(0), decimal64(0)));
}

/**
Returns the value of x rounded up or down, depending on sign (toward zero).
This operation is silent, doesn't throw any exception.
Special_values:
$(BOOKTABLE,
$(TR $(TH x) $(TH trunc(x)))
$(TR $(TD NaN) $(TD NaN))
$(TR $(TD ±0.0) $(TD ±0.0))
$(TR $(TD ±∞) $(TD ±∞))
)
*/
@safe pure nothrow @nogc
D trunc(D)(auto const ref D x)
{
    auto result = canonical(x);
    if (isNaN(x) || isInfinity(x) || isZero(x))
        return result;
    decimalRound(result, RoundingMode.towardZero);
    return result;
}

/**
Gives the previous power of 10 before x. 
Throws:
    $(MYREF InvalidOperationException),
    $(MYREF OverflowException),
    $(MYREF UnderflowException),
    $(MYREF InexactException)
Special_values:
$(BOOKTABLE,
    $(TR $(TH x) $(TH truncPow10(x)))
    $(TR $(TD NaN) $(TD NaN))
    $(TR $(TD ±∞) $(TD ±∞))
    $(TR $(TD ±0.0) $(TD ±0.0))
)
*/
D truncPow10(D)(auto const ref D x)
if (isDecimal!D)
{
    ExceptionFlags flags;
    Unqual!D result;

    if (isSignaling(x))
    {
        result = D.nan;
        flags = ExceptionFlags.invalidOperation;
    }
    else if (isNaN(x) || isInfinity(x) || isZero(x))
        result = x;
    else
    {
        alias U = DataType!D;
        U c;
        int e;
        bool s = x.unpack(c, e);
        for (size_t i = 0; i < pow10!U.length; ++i)
        {
            if (c == pow10!U[i])
                break;
            else if (c < pow10!U[i])
            {
                c = pow10!U[i - 1];
                break;
            }
        }
        if (i == pow10!U.length)
            c = pow10!U[$ - 1];
        flags = adjustCoefficient(c, e, D.EXP_MIN, D.EXP_MAX, D.COEF_MAX, s, RoundingMode.towardZero);
        flags |= result.pack(c, e, s, flags);
    }

    if (__ctfe)
        DecimalControl.checkFlags(flags, ExceptionFlags.severe);
    else
    {
        if (flags)
            DecimalControl.raiseFlags(flags);
    }
    return result;
}


























































































private:

template DataType(D)
{
    static if (is(Unqual!D == decimal32))
        alias DataType = uint;
    else static if (is(Unqual!D == decimal64))
        alias DataType = ulong;
    else static if (is(Unqual!D == decimal128))
        alias DataType = uint128;
    else
        static assert(0);
}

mixin template ExceptionConstructors()
{
    @nogc @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }

    @nogc @safe pure nothrow this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }
}


/* ****************************************************************************************************************** */
/* DECIMAL STRING CONVERSION                                                                                          */
/* ****************************************************************************************************************** */





//sinks %a
void sinkHexadecimal(C, T)(auto const ref FormatSpec!C spec, scope void delegate(const(C)[]) sink, 
                           auto const ref T coefficient, const int exponent, const bool signed) 
if (isSomeChar!C && isAnyUnsigned!T)
{
    int w = 4; //0x, p, exponent sign
    if (spec.flPlus || spec.flSpace || signed)
        ++w;

    int p = prec(coefficient);
    if (p == 0)
        p = 1;

    int precision = spec.precision == spec.UNSPECIFIED || spec.precision <= 0 ? p : spec.precision;

    Unqual!T c = coefficient;
    int e = exponent;

    coefficientAdjust(c, e, precision, signed, __ctfe ? RoundingMode.implicit : DecimalControl.rounding);


    Unqual!C[T.sizeof / 2] buffer;
    Unqual!C[prec(uint.max)] exponentBuffer;

    int digits = dumpUnsignedHex(buffer, c, spec.spec <= 'Z');

    bool signedExponent = e < 0;
    uint ex = signedExponent ? -e : e;
    int exponentDigits = dumpUnsigned(exponentBuffer, ex);

    w += digits;
    w += exponentDigits;

    int pad = spec.width - w;
    sinkPadLeft(spec, sink, pad);
    sinkSign(spec, sink, signed);
    sink("0");
    sink(spec.spec <= 'Z' ? "X" : "x");
    sinkPadZero(spec, sink, pad);
    sink(buffer[$ - digits .. $]);
    sink(spec.spec < 'Z' ? "P" : "p");
    sink(signedExponent ? "-" : "+");
    sink(exponentBuffer[$ - exponentDigits .. $]);
    sinkPadRight(sink, pad);
}


//sinks %f
void sinkFloat(C, T)(auto const ref FormatSpec!C spec, scope void delegate(const(C)[]) sink, const T coefficient, 
                     const int exponent, const bool signed, const RoundingMode mode, const bool skipTrailingZeros = false) 
if (isSomeChar!C)
{
    if (coefficient == 0U)
        sinkZero(spec, sink, signed, skipTrailingZeros);
    else
    {
        Unqual!T c = coefficient;
        int e = exponent;
        coefficientShrink(c, e);

        Unqual!C[40] buffer;
        int w = spec.flPlus || spec.flSpace || signed ? 1 : 0;

        if (e >= 0) //coefficient[0...].[0...]
        {
            ptrdiff_t digits = dumpUnsigned(buffer, c);
            w += digits;
            w += e;
            int requestedDecimals = spec.precision == spec.UNSPECIFIED ? 6 : spec.precision;
            if (skipTrailingZeros)
                requestedDecimals = 0;
            if (requestedDecimals || spec.flHash)
                w += requestedDecimals + 1;
            int pad = spec.width - w;
            sinkPadLeft(spec, sink, pad);
            sinkSign(spec, sink, signed);
            sinkPadZero(spec, sink, pad);
            sink(buffer[$ - digits .. $]);
            sinkRepeat(sink, '0', e);
            if (requestedDecimals || spec.flHash)
            {
                sink(".");
                sinkRepeat(sink, '0', requestedDecimals);
            }
            sinkPadRight(sink, pad);
        }
        else
        {
            int digits = prec(c);
            int requestedDecimals = spec.precision == spec.UNSPECIFIED ? 6 : spec.precision;

            if (-e < digits) //coef.ficient[0...]
            {
                int integralDigits = digits + e;
                int fractionalDigits = digits - integralDigits;
                if (fractionalDigits > requestedDecimals)
                {
                    divpow10(c, fractionalDigits - requestedDecimals, signed, mode);
                    digits = prec(c);
                    fractionalDigits = digits - integralDigits;
                    if (fractionalDigits > requestedDecimals)
                    {
                        c /= 10U;
                        --fractionalDigits;
                    }
                }
                if (requestedDecimals > fractionalDigits && skipTrailingZeros)
                    requestedDecimals = fractionalDigits;
                w += integralDigits;
                if (requestedDecimals || spec.flHash)
                    w += requestedDecimals + 1;
                int pad = spec.width - w;
                sinkPadLeft(spec, sink, pad);
                sinkSign(spec, sink, signed);
                sinkPadZero(spec, sink, pad);
                dumpUnsigned(buffer, c);
                sink(buffer[$ - digits .. $ - fractionalDigits]);
                if (requestedDecimals || spec.flHash)
                {
                    sink(".");
                    if (fractionalDigits)
                        sink(buffer[$ - fractionalDigits .. $]);
                    sinkRepeat(sink, '0', requestedDecimals - fractionalDigits);
                }
                sinkPadRight(sink, pad);
            }
            else if (-e == digits) //0.coefficient[0...]
            {
                if (skipTrailingZeros && requestedDecimals > digits)
                    requestedDecimals = digits;
                if (requestedDecimals == 0) //special case, no decimals, round
                {
                    divpow10(c, digits - 1, signed, mode);
                    divpow10(c, 1, signed, mode);
                    w += 1;
                    if (spec.flHash)
                        ++w;
                    int pad = spec.width - w;
                    sinkPadLeft(spec, sink, pad);
                    sinkSign(spec, sink, signed);
                    sinkPadZero(spec, sink, pad);
                    sink(c != 0U ? "1": "0");
                    if (spec.flHash)
                        sink(".");
                    sinkPadRight(sink, pad);
                }
                else
                {
                    w += 2;
                    w += requestedDecimals;
                    if (digits > requestedDecimals)
                    {
                        divpow10(c, digits - requestedDecimals, signed, mode);
                        digits = prec(c);
                        if (digits > requestedDecimals)
                        {
                            c /= 10U;
                            --digits;
                        }
                    }
                    int pad = spec.width - w;
                    sinkPadLeft(spec, sink, pad);
                    sinkSign(spec, sink, signed);
                    sinkPadZero(spec, sink, pad);
                    sink("0.");
                    dumpUnsigned(buffer, c);
                    sink(buffer[$ - digits .. $]);
                    sinkRepeat(sink, '0', requestedDecimals - digits);
                    sinkPadRight(sink, pad);
                }
            }
            else //-e > 0.[0...][coefficient]
            {
                int zeros = -e - digits;
                
                if (requestedDecimals > digits - e && skipTrailingZeros)
                    requestedDecimals = digits - e - 1;

                if (requestedDecimals <= zeros) //special case, coefficient does not fit
                {
                    divpow10(c, digits - 1, signed, mode);
                    divpow10(c, 1, signed, mode);
                    if (requestedDecimals == 0)  //special case, 0 or 1
                    {
                        w += 1;
                        int pad = spec.width - w;
                        sinkPadLeft(spec, sink, pad);
                        sinkSign(spec, sink, signed);
                        sinkPadZero(spec, sink, pad);
                        sink(c != 0U ? "1": "0");
                        sinkPadRight(sink, pad);
                    }
                    else  //special case 0.[0..][0/1]
                    {
                        w += 2;
                        w += requestedDecimals;
                        int pad = spec.width - w;
                        sinkPadLeft(spec, sink, pad);
                        sinkSign(spec, sink, signed);
                        sinkPadZero(spec, sink, pad);
                        sink("0.");
                        sinkRepeat(sink, '0', requestedDecimals - 1);
                        sink(c != 0U ? "1": "0");
                        sinkPadRight(sink, pad);
                    }
                }
                else //0.[0...]coef
                {
                    if (digits > requestedDecimals - zeros)
                    {
                        divpow10(c, digits - (requestedDecimals - zeros), signed, mode);
                        digits = prec(c);
                        if (digits > requestedDecimals - zeros)
                            c /= 10U;
                        digits = prec(c);
                    }
                    w += 2;
                    w += requestedDecimals;
                    int pad = spec.width - w;
                    sinkPadLeft(spec, sink, pad);
                    sinkSign(spec, sink, signed);
                    sinkPadZero(spec, sink, pad);
                    sink("0.");
                    sinkRepeat(sink, '0', zeros);
                    digits = dumpUnsigned(buffer, c);
                    sink(buffer[$ - digits .. $]);
                    sinkRepeat(sink, '0', requestedDecimals - digits - zeros);
                    sinkPadRight(sink, pad);
                }
            }
        }
    }
}

//sinks %e
void sinkExponential(C, T)(auto const ref FormatSpec!C spec, scope void delegate(const(C)[]) sink, const T coefficient, 
                     const int exponent, const bool signed, const RoundingMode mode, const bool skipTrailingZeros = false) 
if (isSomeChar!C)
{
    int w = 3; /// N e +/-
    if (spec.flPlus || spec.flSpace || signed)
        ++w;
    Unqual!C[T.sizeof * 8 / 3 + 1] buffer;
    Unqual!C[10] exponentBuffer;
    Unqual!T c = coefficient;
    int ex = exponent;
    coefficientShrink(c, ex);
    int digits = prec(c);
    int e = digits == 0 ? 0 : ex + (digits - 1);    
    int requestedDecimals = spec.precision == spec.UNSPECIFIED ? 6 : spec.precision;

    int targetPrecision = requestedDecimals + 1;

    if (digits > targetPrecision)
    {
        divpow10(c, digits - targetPrecision, signed, mode);
        digits = prec(c);
        if (digits > targetPrecision)
            c /= 10U;
        --digits;
    }
    

    bool signedExponent = e < 0;
    uint ue = signedExponent ? -e : e;
    int exponentDigits = dumpUnsigned(exponentBuffer, ue);
    w += exponentDigits <= 2 ? 2 : exponentDigits;
    digits = dumpUnsigned(buffer, c);

    if (skipTrailingZeros && requestedDecimals > digits - 1)
        requestedDecimals = digits - 1;

    if (requestedDecimals || spec.flHash)
        w += requestedDecimals + 1;
    
    int pad = spec.width - w;
    sinkPadLeft(spec, sink, pad);
    sinkSign(spec, sink, signed);
    sinkPadZero(spec, sink, pad);
    sink(buffer[$ - digits .. $ - digits + 1]);
    if (requestedDecimals || spec.flHash)
    {
        sink(".");
        if (digits > 1)
            sink(buffer[$ - digits + 1 .. $]);
        sinkRepeat(sink, '0', requestedDecimals - (digits - 1));
    }
    sink(spec.spec <= 'Z' ? "E" : "e");
    sink(signedExponent ? "-" : "+");
    if (exponentDigits < 2)
        sink("0");
    sink(exponentBuffer[$ - exponentDigits .. $]);
    sinkPadRight(sink, pad);    
}

//sinks %g
void sinkGeneral(C, T)(auto const ref FormatSpec!C spec, scope void delegate(const(C)[]) sink, const T coefficient, 
                           const int exponent, const bool signed, const RoundingMode mode) 
if (isSomeChar!C)
{
    int precision = spec.precision == spec.UNSPECIFIED ? 6 : (spec.precision <= 0 ? 1 : spec.precision);
    Unqual!T c = coefficient;
    int e = exponent;
    coefficientShrink(c, e);
    coefficientAdjust(c, e, precision, signed, mode);
    if (c == 0U)
        e = 0;
    int cp = prec(c);

    int expe = cp > 0 ? e + cp - 1 : 0;

    if (precision > expe && expe >= -4)
    {
        FormatSpec!C fspec = spec;
        fspec.precision = precision - 1 - expe;
        sinkFloat(fspec, sink, coefficient, exponent, signed, mode, !fspec.flHash);
    }
    else
    {
        FormatSpec!C espec = spec;
        espec.precision = precision - 1;
        sinkExponential(espec, sink, coefficient, exponent, signed, mode, !espec.flHash);
    }

}

//sinks a decimal value
void sinkDecimal(C, D)(auto const ref FormatSpec!C spec, scope void delegate(const(C)[]) sink, auto const ref D decimal,
                       const RoundingMode mode)
if (isDecimal!D && isSomeChar!C)
{
    if (isNaN(decimal))
        sinkNaN(spec, sink, signbit(decimal) != 0, isSignaling(decimal));
    else if (isInfinity(decimal))
        sinkInfinity(spec, sink, signbit(decimal) != 0);
    else
    {
        DataType!D coefficient;
        int exponent;
        bool isNegative = decimal.unpack(coefficient, exponent);
        switch (spec.spec)
        {
            case 'f':
            case 'F':
                sinkFloat(spec, sink, coefficient, exponent, isNegative, mode);
                break;
            case 'e':
            case 'E':
                sinkExponential(spec, sink, coefficient, exponent, isNegative, mode);
                break;
            case 'g':
            case 'G':
            case 's':
            case 'S':
                sinkGeneral(spec, sink, coefficient, exponent, isNegative, mode);
                break;
            case 'a':
            case 'A':
                sinkHexadecimal(spec, sink, coefficient, exponent, isNegative);
                break;
            default:
                throw new FormatException("Unsupported format specifier");
        }
    }
}

//converts decimal to string using %g
immutable(C)[] decimalToString(C, D)(auto const ref D decimal, const RoundingMode mode)
if (isDecimal!D && isSomeChar!C) 
{
    immutable(C)[] result;
    void localSink(const(C)[] s)
    {
        result ~= s;
    }

    sinkDecimal(FormatSpec!C("%g"), &localSink, decimal, mode);

    return result;
}

//converts decimal to string
immutable(C)[] decimalToString(C, D)(auto const ref FormatSpec!C spec, auto const ref D decimal, const RoundingMode mode)
if (isDecimal!D && isSomeChar!C) 
{
    immutable(C)[] result;
    void localSink(const(C)[] s)
    {
        result ~= s;
    }

    sinkDecimal(spec, &localSink, decimal, mode);

    return result;
}

unittest
{
    import std.format;
    decimal32 x = "1.234567";
    assert (format("%0.7f", x) == "1.2345670");
    assert (format("%0.6f", x) == "1.234567");
    assert (format("%0.5f", x) == "1.23457");
    assert (format("%0.4f", x) == "1.2346");
    assert (format("%0.3f", x) == "1.235");
    assert (format("%0.2f", x) == "1.23");
    assert (format("%0.1f", x) == "1.2");
    assert (format("%0.0f", x) == "1");
    assert (format("%+0.1f", x) == "+1.2");
    assert (format("%+0.1f", -x) == "-1.2");
    assert (format("% 0.1f", x) == " 1.2");
    assert (format("% 0.1f", -x) == "-1.2");
    assert (format("%8.2f", x) == "    1.23");
    assert (format("%+8.2f", x) == "   +1.23");
    assert (format("%+8.2f", -x) == "   -1.23");
    assert (format("% 8.2f", x) == "    1.23");
    assert (format("%-8.2f", x) == "1.23    ");
    assert (format("%-8.2f", -x) == "-1.23   ");

    struct S 
    {
        string fmt;
        string v;
        string expected;
    }
    
    S[] tests = 
    [
        S("%+.3e","0.0","+0.000e+00"),
  	    S("%+.3e","1.0","+1.000e+00"),
  	    S("%+.3f","-1.0","-1.000"),
  	    S("%+.3F","-1.0","-1.000"),
  	    S("%+07.2f","1.0","+001.00"),
  	    S("%+07.2f","-1.0","-001.00"),
  	    S("%-07.2f","1.0","1.00   "),
  	    S("%-07.2f","-1.0","-1.00  "),
  	    S("%+-07.2f","1.0","+1.00  "),
  	    S("%+-07.2f","-1.0","-1.00  "),
  	    S("%-+07.2f","1.0","+1.00  "),
  	    S("%-+07.2f","-1.0","-1.00  "),
  	    S("%+10.2f","+1.0","     +1.00"),
  	    S("%+10.2f","-1.0","     -1.00"),
  	    S("% .3E","-1.0","-1.000E+00"),
  	    S("% .3e","1.0"," 1.000e+00"),
  	    S("%+.3g","0.0","+0"),
  	    S("%+.3g","1.0","+1"),
  	    S("%+.3g","-1.0","-1"),
  	    S("% .3g","-1.0","-1"),
  	    S("% .3g","1.0"," 1"),
  	    S("%a","1.0","0x1p+0"),
  	    S("%#g","1e-32","1.00000e-32"),
  	    S("%#g","-1.0","-1.00000"),
  	    S("%#g","1.1","1.10000"),
  	    S("%#g","123456.0","123456."),
  	    S("%#g","1234567.0","1.23457e+06"),
  	    S("%#g","1230000.0","1.23000e+06"),
  	    S("%#g","1000000.0","1.00000e+06"),
  	    S("%#.0f","1.0","1."),
  	    S("%#.0e","1.0","1.e+00"),
  	    S("%#.0g","1.0","1."),
  	    S("%#.0g","1100000.0","1.e+06"),
  	    S("%#.4f","1.0","1.0000"),
  	    S("%#.4e","1.0","1.0000e+00"),
  	    S("%#.4g","1.0","1.000"),
  	    S("%#.4g","100000.0","1.000e+05"),
  	    S("%#.0f","123.0","123."),
  	    S("%#.0e","123.0","1.e+02"),
  	    S("%#.0g","123.0","1.e+02"),
  	    S("%#.4f","123.0","123.0000"),
  	    S("%#.4e","123.0","1.2300e+02"),
  	    S("%#.4g","123.0","123.0"),
  	    S("%#.4g","123000.0","1.230e+05"),
  	    S("%#9.4g","1.0","    1.000"),
  	    S("%.4a","1.0","0x1p+0"),
  	    S("%.4a","-1.0","-0x1p+0"),
  	    S("%f","+inf","inf"),
  	    S("%.1f","-inf","-inf"),
  	    S("% f","NaN"," nan"),
  	    S("%20f","+inf","                 inf"),
  	    S("% 20F","+inf","                 INF"),
  	    S("% 20e","-inf","                -inf"),
  	    S("%+20E","-inf","                -INF"),
  	    S("% +20g","-Inf","                -inf"),
  	    S("%+-20G","+inf","+INF                "),
  	    S("%20e","NaN","                 nan"),
  	    S("% +20E","NaN","                +NAN"),
  	    S("% -20g","NaN"," nan                "),
  	    S("%+-20G","NaN","+NAN                "),
  	    S("%+020e","+inf","                +inf"),
  	    S("%-020f","-inf","-inf                "),
  	    S("%-020E","NaN","NAN                 "),
        S("%e","1.0","1.000000e+00"),
  	    S("%e","1234.5678e3","1.234568e+06"),
  	    S("%e","1234.5678e-8","1.234568e-05"),
  	    S("%e","-7.0","-7.000000e+00"),
  	    S("%e","-1e-9","-1.000000e-09"),
  	    S("%f","1234.567e2","123456.700000"),
  	    S("%f","1234.5678e-8","0.000012"),
  	    S("%f","-7.0","-7.000000"),
  	    S("%f","-1e-9","-0.000000"),
  	    S("%g","1234.5678e3","1.23457e+06"),
  	    S("%g","1234.5678e-8","1.23457e-05"),
  	    S("%g","-7.0","-7"),
  	    S("%g","-1e-9","-1e-09"),
  	    S("%E","1.0","1.000000E+00"),
  	    S("%E","1234.5678e3","1.234568E+06"),
  	    S("%E","1234.5678e-8","1.234568E-05"),
  	    S("%E","-7.0","-7.000000E+00"),
  	    S("%E","-1e-9","-1.000000E-09"),
  	    S("%G","1234.5678e3","1.23457E+06"),
  	    S("%G","1234.5678e-8","1.23457E-05"),
  	    S("%G","-7.0","-7"),
  	    S("%G","-1e-9","-1E-09"),
  	    S("%20.6e","1.2345e3","        1.234500e+03"),
  	    S("%20.6e","1.2345e-3","        1.234500e-03"),
  	    S("%20e","1.2345e3","        1.234500e+03"),
  	    S("%20e","1.2345e-3","        1.234500e-03"),
  	    S("%20.8e","1.2345e3","      1.23450000e+03"),
  	    S("%20f","1.23456789e3","         1234.568000"),
  	    S("%20f","1.23456789e-3","            0.001235"),
  	    S("%20f","12345678901.23456789","  12345680000.000000"),
  	    S("%-20f","1.23456789e3","1234.568000         "),
        S("%20.8f","1.23456789e3","       1234.56800000"),
        S("%20.8f","1.23456789e-3","          0.00123457"),
        S("%g","1.23456789e3","1234.57"),
        S("%g","1.23456789e-3","0.00123457"),
        S("%g","1.23456789e20","1.23457e+20"),
        S("%.2f","1.0","1.00"),
  	    S("%.2f","-1.0","-1.00"),
  	    S("% .2f","1.0"," 1.00"),
  	    S("% .2f","-1.0","-1.00"),
  	    S("%+.2f","1.0","+1.00"),
  	    S("%+.2f","-1.0","-1.00"),
  	    S("%7.2f","1.0","   1.00"),
  	    S("%7.2f","-1.0","  -1.00"),
  	    S("% 7.2f","1.0","   1.00"),
  	    S("% 7.2f","-1.0","  -1.00"),
  	    S("%+7.2f","1.0","  +1.00"),
  	    S("%+7.2f","-1.0","  -1.00"),
  	    S("% +7.2f","1.0","  +1.00"),
  	    S("% +7.2f","-1.0","  -1.00"),
  	    S("%07.2f","1.0","0001.00"),
  	    S("%07.2f","-1.0","-001.00"),
  	    S("% 07.2f","1.0"," 001.00"),
  	    S("% 07.2f","-1.0","-001.00"),
  	    S("%+07.2f","1.0","+001.00"),
  	    S("%+07.2f","-1.0","-001.00"),
  	    S("% +07.2f","1.0","+001.00"),
  	    S("% +07.2f","-1.0","-001.00"),
  
  
    ];

    foreach(s; tests)
    {
        string result = format(s.fmt, decimal32(s.v));
        assert(result == s.expected, "value: '" ~ s.v ~ "', format: '" ~ s.fmt ~ "', result :'" ~ result ~ "', expected: '" ~ s.expected ~ "'");
    }
}


//returns true if a decimal number can be read in value, stops if doesn't fit in value
ExceptionFlags parseNumberAndExponent(R, T)(ref R range, out T value, out int exponent, bool zeroPrefix) 
if (isInputRange!R && isSomeChar!(ElementType!R))
{
    bool afterDecimalPoint = false;
    bool atLeastOneDigit = parseZeroes(range) > 0 || zeroPrefix;
    bool atLeastOneFractionalDigit = false;
    ExceptionFlags flags = ExceptionFlags.none;
    while (!range.empty)
    {
        if (range.front >= '0' && range.front <= '9')
        {
            uint digit = range.front - '0';
            bool overflow = false;
            Unqual!T v = fma(value, 10U, digit, overflow);
            if (overflow)
                break;
            range.popFront();
            value = v;
            if (afterDecimalPoint)
            {
                atLeastOneFractionalDigit = true;
                --exponent;
            }
            else
                atLeastOneDigit = true;
        }
        else if (range.front == '.' && !afterDecimalPoint)
        {
            afterDecimalPoint = true;
            range.popFront();
        }
        else if (range.front == '_')
            range.popFront();
        else
            break;
    }

    //no more space in coefficient, just increase exponent before decimal point
    //detect if rounding is necessary
    int lastDigit = 0;
    bool mustRoundUp = false;
    while (!range.empty)
    {
        if (range.front >= '0' && range.front <= '9')
        {       
            uint digit = range.front - '0';
            if (afterDecimalPoint)
                atLeastOneFractionalDigit = true;
            else
                ++exponent;
            range.popFront();
            if (digit != 0)
                flags = ExceptionFlags.inexact;
            if (digit <= 3)
                break;
            else if (digit >= 5)
            {
                if (lastDigit == 4)
                {
                    mustRoundUp = true;
                    break;
                }
            }
            else
                lastDigit = 4;

        }
        else if (range.front == '.' && !afterDecimalPoint)
        {
            afterDecimalPoint = true;
            range.popFront();
        }
        else if (range.front == '_')
            range.popFront();
        else
            break;
    }

    //just increase exponent before decimal point
    while (!range.empty)
    {
        if (range.front >= '0' && range.front <= '9')
        {       
            if (range.front != '0')
                flags = ExceptionFlags.inexact;
            if (!afterDecimalPoint)
               ++exponent;
            else
                atLeastOneFractionalDigit = true;
            range.popFront();
        }
        else if (range.front == '.' && !afterDecimalPoint)
        {
            afterDecimalPoint = true;
            range.popFront();
        }
        else if (range.front == '_')
            range.popFront();
        else
            break;
    }

    if (mustRoundUp)
    {
        if (value < T.max)
            ++value;
        else
        {
            auto r = divrem(value, 10U);
            ++value;
            if (r >= 5U)
                ++value;
            else if (r == 4U && mustRoundUp)
                ++value;
        }
    }


    if (afterDecimalPoint)
        return atLeastOneFractionalDigit ? flags : flags | ExceptionFlags.invalidOperation;
    else
        return atLeastOneDigit ? flags : flags | ExceptionFlags.invalidOperation;
}

//parses hexadecimals if starts with 0x, otherwise decimals, false on failure
bool parseHexNumberOrNumber(R, T)(ref R range, ref T value, out bool wasHex) 
if (isInputRange!R && isSomeChar!(ElementType!R))
{
    if (expect(range, '0'))
    {
        if (expectInsensitive(range, 'x'))
        {
            wasHex = true;
            return parseHexNumber(range, value);
        }
        else
            return parseNumber(range, value);
    }
    else
        return parseNumber(range, value);
}

//parses NaN and optional payload, expect payload as number in optional (), [], {}, <>. invalidOperation on failure
bool parseNaN(R, T)(ref R range, out T payload) 
if (isInputRange!R && isSomeChar!(ElementType!R))
{
    if (expectInsensitive(range, "nan"))
    {
        auto closingBracket = parseBracket(range);  
        bool wasHex;
        if (!parseHexNumberOrNumber(range, payload, wasHex))
        {
            if (wasHex)
                return false;
        }
        if (closingBracket)
            return expect(range, closingBracket);
        return true;
    }
    return false;
}

@safe
ExceptionFlags parseDecimalHex(R, T)(ref R range, out T coefficient, out int exponent)
if (isInputRange!R && isSomeChar!(ElementType!R))
{
    if (parseHexNumber(range, coefficient))
    {
        if (expectInsensitive(range, 'p'))
        {
            bool signedExponent;
            parseSign(range, signedExponent);
            uint e;
            if (parseNumber(range, e))
            {
                if (signedExponent && e > -int.min)
                {
                    exponent = int.min;
                    return ExceptionFlags.underflow;
                }
                else if (!signedExponent && e > int.max)
                {
                    exponent = int.max;
                    return ExceptionFlags.overflow;
                }
                exponent = signedExponent ? -e : e;
                return ExceptionFlags.none;
            }
        }
    }
    return ExceptionFlags.invalidOperation;
}

ExceptionFlags parseDecimalFloat(R, T)(ref R range, out T coefficient, out int exponent, const bool zeroPrefix)
if (isInputRange!R && isSomeChar!(ElementType!R))
{
    auto flags = parseNumberAndExponent(range, coefficient, exponent, zeroPrefix);
    if ((flags & ExceptionFlags.invalidOperation) == 0)
    {
        coefficientShrink(coefficient, exponent);
        if (expectInsensitive(range, 'e'))
        {
            bool signedExponent;
            parseSign(range, signedExponent);
            uint ue;
            if (!parseNumber(range, ue))
                flags |= ExceptionFlags.invalidOperation;
            else
            {       
                
                bool overflow;          
                if (!signedExponent)
                {
                    if (ue > int.max)
                    {
                        exponent = int.max;
                        flags |= ExceptionFlags.overflow;
                    }
                    else
                        exponent = adds(exponent, cast(int)ue, overflow);
                }
                else
                {
                    if (ue > -int.min || overflow)
                    {
                        exponent = int.min;
                        flags |= ExceptionFlags.underflow;
                    }
                    else
                        exponent = adds(exponent, cast(int)(-ue), overflow);
                }
                if (overflow)
                    flags |= exponent > 0 ? ExceptionFlags.underflow : ExceptionFlags.overflow;
            }
        }
    }
    return flags;
}

@safe
ExceptionFlags parseDecimal(R, T)(ref R range, out T coefficient, out int exponent, out bool isinf, out bool isnan, 
                                  out bool signaling, out bool signed, out bool wasHex)
if (isInputRange!R && isSomeChar!(ElementType!R))
{
    while (expect(range, '_')) { }
    if (range.empty)
        return ExceptionFlags.invalidOperation;
    bool hasSign = parseSign(range, signed);
    if (range.empty && hasSign)
        return ExceptionFlags.invalidOperation;
    while (expect(range, '_')) { }
    switch (range.front)
    {
        case 'i':
        case 'I':
            isinf = true;
            return parseInfinity(range) ? ExceptionFlags.none : ExceptionFlags.invalidOperation;
        case 'n':
        case 'N':
            isnan = true;
            signaling = false;
            return parseNaN(range, coefficient) ? ExceptionFlags.none : ExceptionFlags.invalidOperation;
        case 's':
        case 'S':
            isnan = true;
            signaling = true;
            range.popFront();
            return parseNaN(range, coefficient) ? ExceptionFlags.none : ExceptionFlags.invalidOperation;
        case '0':
            range.popFront();
            if (expectInsensitive(range, 'x'))
            {
                wasHex = true;
                return parseDecimalHex(range, coefficient, exponent);
            }
            else
                return parseDecimalFloat(range, coefficient, exponent, true);
        case '1': .. case '9':
            return parseDecimalFloat(range, coefficient, exponent, false);
        default:
            return ExceptionFlags.invalidOperation;
    }
}

ExceptionFlags parse(D, R)(ref R range, out D decimal, const int precision, const RoundingMode mode)
if (isInputRange!R && isSomeChar!(ElementType!R) && isDecimal!D)
{
    DataType!D coefficient;
    bool isinf, isnan, signaling, signed;
    int exponent;
    auto flags = parseDecimal(range, coefficient, exponent, isinf, isnan, signaling, isnegative);
 
    if (flags & ExceptionFlags.invalidOperation)
    {   
        decimal.data = D.MASK_QNAN;
        decimal.data |= coefficient | D.MASK_PAYL;
        if (isnegative)
            decimal.data |= D.MASK_SGN;
        return flags;
    }

    if (signaling)
        decimal.data = D.MASK_SNAN;
    else if (isnan)
        decimal.data = D.MASK_QNAN;
    else if (isinf)
        decimal.data = D.MASK_INF;
    else if (coefficient == 0)
        decimal.data - D.MASK_ZERO;
    else
    {
        flags |= adjustCoefficient(coefficient, exponent, D.EXP_MIN, D.EXP_MAX, D.COEF_MAX, isnegative, mode);
        flags |= adjustPrecision(coefficient, exponent, D.EXP_MIN, D.EXP_MAX, precision, isnegative, mode);
        if (flags & ExceptionFlags.overflow)
            decimal.data = D.MASK_INF;
        else if ((flags & ExceptionFlags.underflow)  || coefficient == 0)
            decimal.data = D.MASK_ZERO;
        else
        {
            flags |= decimal.pack(coefficient, exponent, isnegative);
            if (flags & ExceptionFlags.overflow)
                decimal.data = D.MASK_INF;
            else if ((flags & ExceptionFlags.underflow)  || coefficient == 0)
                decimal.data = D.MASK_ZERO;                
        }
    }

    if (isNegative)
        decimal.data |= D.MASK_SGN;
    return flags;
}

D fromString(D, C)(const(C)[] s)
if (isDecimal!D && isSomeChar!C)
{
    Unqual!D result = void;
    auto flags = result.packString(s, 
                                   __ctfe ? D.PRECISION : DecimalControl.precision,
                                   __ctfe ? RoundingMode.implicit: DecimalControl.rounding);
    DecimalControl.raiseFlags(flags);
    return result;
}






/* ****************************************************************************************************************** */
/* DECIMAL TO DECIMAL CONVERSION                                                                                      */
/* ****************************************************************************************************************** */

ExceptionFlags decimalToDecimal(D1, D2)(auto const ref D1 source, out D2 target, 
                                        const int precision, const RoundingMode mode) 
if (isDecimal!(D1, D2))
{
    ExceptionFlags flags;
    static if (D1.sizeof == D2.sizeof)
    {
        target = source;
        return ExceptionFlags.none;
    }
    else
    {
        if (isSignaling(source))
            target = copysign(D2.snan, source);
        else if (isNaN(source))
            target = copysign(D2.nan, source);
        else if (isInfinity(source))
            target = copysign(D2.infinity, source);
        else if (isZero(source))
            target = copysign(D2.zero, source);
        else
        {
            DataType!D1 csource;
            DataType!D2 ctarget;
            int exponent;
            bool isNegative = source.unpack(csource, exponent);
            int targetPrecision = D2.realPrecision(precision);
            static if (D1.sizeof > D2.sizeof)
            {
                flags = coefficientAdjust(csource, exponent, D2.PRECISION, isNegative, mode);
                ctarget = cast(DataType!D2)csource;
            }
            else
            {
                ctarget = csource;
            }
            flags = target.adjustedPack(ctarget, exponent, isNegative, precision, mode, flags);
        }
        return flags;
    }
}

ExceptionFlags decimalToUnsigned(D, T)(auto const ref D source, out T target, const RoundingMode mode) 
if (isDecimal!D && isUnsigned!T)
{
    
    if (isNaN(source))
    {
        target = 0;
        return ExceptionFlags.invalidOperation;
    }

    if (isInfinity(source))
    {
        target = signbit(source) != 0 ? T.min : T.max;
        return ExceptionFlags.overflow;
    }

    if (isZero(source))
    {
        target = 0;
        return ExceptionFlags.none;
    }

    if (signbit(source) != 0)
    {
        target = 0;
        return ExceptionFlags.overflow;
    }
    

    DataType!D coefficient;
    int exponent;
    source.unpack(coefficient, exponent);
    
    static if (T.sizeof > DataType!D.sizeof)
    {
        Unqual!T c = coefficient;
        Unqual!T max = T.max;
    }
    else
    {
        alias c = coefficient;
        DataType!D max = T.max;
    }

    auto flags = coefficientAdjust(c, exponent, 0, 0, max, false, mode);
    target = cast(T)c;
    return flags;
}


ExceptionFlags decimalToSigned(D, T)(auto const ref D source, out T target, const RoundingMode mode) 
if (isDecimal!D && isSigned!T)
{

    if (isNaN(source))
        return ExceptionFlags.invalidOperation;

    if (isInfinity(source))
    {
        target = signbit(source) != 0 ? T.min : T.max;
        return ExceptionFlags.overflow;
    }

    if (isZero(source))
    {
        target = 0;
        return ExceptionFlags.none;
    }


    DataType!D coefficient;
    int exponent;
    bool isNegative = source.unpack(coefficient, exponent);

    static if (T.sizeof > DataType!D.sizeof)
    {
        Unqual!(Unsigned!T) c = coefficient;
        Unqual!(Unsigned!T) max = isNegative ? -T.min : T.max;
    }
    else
    {
        alias c = coefficient;
        DataType!D max = (isNegative ? cast(Unsigned!(Unqual!T))(-T.min) : cast(Unsigned!(Unqual!T))T.max);
    }

    auto flags = coefficientAdjust(c, exponent, 0, 0, max, isNegative, mode);
    target = isNegative ? -cast(Unsigned!T)c : cast(Unsigned!T)c;
    return flags;
}

ExceptionFlags decimalToFloat(D, T)(auto const ref D source, out T target, const RoundingMode mode)
if (isDecimal!D && isFloatingPoint!T)
{
    if (isNaN(source))
    {
        target = T.nan;
        return ExceptionFlags.none;
    }

    if (isInfinity(source))
    {
        target = signbit(source) != 0 ? -T.infinity : T.infinity;
        return ExceptionFlags.none;
    }

    if (isZero(source))
    {
        target = signbit(source) != 0 ? -0.0: 0.0;
        return ExceptionFlags.none;
    }

    DataType!D coefficient;
    int exponent;
    bool isNegative = source.unpack(coefficient, exponent);
    ExceptionFlags flags;

    static if (is(Unqual!D == decimal128))
    {
        flags = adjustCoefficient(coefficient, exponent, uint128(ulong.max), isNegative, mode);
    }

    ulong c = cast(ulong)coefficient;

    FloatingPointControl fpctrl;
    auto savedExceptions = fpctrl.enabledExceptions;
    fpctrl.disableExceptions(FloatingPointControl.allExceptions);

    target = c;
    while (exponent > 0)
    {
        int pow = exponent > pow10_64.length - 1 ? pow10_64.length - 1 : exponent;
        target *= pow10_64[pow];
        exponent -= pow;
    }

    exponent = -exponent;

    while (exponent > 0)
    {
        int pow = exponent > pow10_64.length - 1 ? pow10_64.length - 1 : exponent;
        target /= pow10_64[pow];
        exponent -= pow;
    }

    fpctrl.enableExceptions(savedExceptions);

    return flags;

}

/* ****************************************************************************************************************** */
/* DECIMAL ARITHMETIC                                                                                      */
/* ****************************************************************************************************************** */

DecimalClass decimalDecode(D, T)(auto const ref D x, out T cx, out int ex, out bool sx) 
if (isDecimal!D && is(T: DataType!D))
{
    sx = cast(bool)(x.data & D.MASK_SGN);

    if ((x.data & D.MASK_INF) == D.MASK_INF)
        if ((x.data & D.MASK_QNAN) == D.MASK_QNAN)
            if ((x.data & D.MASK_SNAN) == D.MASK_SNAN)
                return DecimalClass.signalingNaN;
            else
                return DecimalClass.quietNaN;
        else
            return sx ? DecimalClass.negativeInfinity : DecimalClass.positiveInfinity;
    else if ((x.data & D.MASK_EXT) == D.MASK_EXT)
    {
        cx = (x.data & D.MASK_COE2) | D.MASK_COEX;
        if (cx > D.COEF_MAX)
        {
            return x.data & D.MASK_SGN ? DecimalClass.negativeZero : DecimalClass.positiveZero; 
        }
        ex = cast(uint)((x.data & D.MASK_EXP2) >>> D.SHIFT_EXP2) - D.EXP_BIAS;
    }
    else
    {
        cx = x.data & D.MASK_COE1;
        if (cx == 0U)
        {
            ex = 0;
            return sx ? DecimalClass.negativeZero : DecimalClass.positiveZero; 
        }
        ex = cast(uint)((x.data & D.MASK_EXP1) >>> D.SHIFT_EXP1) - D.EXP_BIAS;
    }

    if (ex + D.EXP_BIAS < D.PRECISION - 1)
    {
        if (prec(cx) < D.PRECISION - ex + D.EXP_BIAS)
            return sx ? DecimalClass.negativeSubnormal : DecimalClass.positiveSubnormal;
    }
    return sx ? DecimalClass.negativeNormal : DecimalClass.positiveNormal;
}

enum FastClass
{
    signalingNaN,
    quietNaN,
    infinite,
    zero,
    finite,
}

FastClass fastDecode(D, T)(auto const ref D x, out T cx, out int ex, out bool sx) 
if ((is(D: decimal32) || is(D: decimal64)) && isAnyUnsigned!T)
{
    static assert (T.sizeof >= D.sizeof);

    sx = cast(bool)(x.data & D.MASK_SGN);

    if ((x.data & D.MASK_INF) == D.MASK_INF)
        if ((x.data & D.MASK_QNAN) == D.MASK_QNAN)
            if ((x.data & D.MASK_SNAN) == D.MASK_SNAN)
                return FastClass.signalingNaN;
            else
                return FastClass.quietNaN;
        else
            return FastClass.infinite;
    else if ((x.data & D.MASK_EXT) == D.MASK_EXT)
    {
        cx = (x.data & D.MASK_COE2) | D.MASK_COEX;
        if (cx > D.COEF_MAX)
            return FastClass.zero;
        ex = cast(uint)((x.data & D.MASK_EXP2) >>> D.SHIFT_EXP2) - D.EXP_BIAS;
    }
    else
    {
        cx = x.data & D.MASK_COE1;
        if (cx == 0U)
            return FastClass.zero;
        ex = cast(uint)((x.data & D.MASK_EXP1) >>> D.SHIFT_EXP1) - D.EXP_BIAS;
    }

    return FastClass.finite;
}

FastClass fastDecode(D, T)(auto const ref D x, out T cx, out int ex, out bool sx) 
if (is(D: decimal128) && isAnyUnsigned!T)
{
    static assert (T.sizeof >= D.sizeof);

    sx = cast(bool)(x.data.hi & D.MASK_SGN.hi);

    if ((x.data.hi & D.MASK_INF.hi) == D.MASK_INF.hi)
        if ((x.data.hi & D.MASK_QNAN.hi) == D.MASK_QNAN.hi)
            if ((x.data & D.MASK_SNAN.hi) == D.MASK_SNAN.hi)
                return FastClass.signalingNaN;
            else
                return FastClass.quietNaN;
        else
            return FastClass.infinite;
    else if ((x.data & D.MASK_EXT.hi) == D.MASK_EXT.hi)
    {
        cx = (x.data & D.MASK_COE2) | D.MASK_COEX;
        if (cx > D.COEF_MAX)
            return FastClass.zero;
        ex = cast(uint)((x.data.hi & D.MASK_EXP2.hi) >>> (D.SHIFT_EXP2 - 64)) - D.EXP_BIAS;
    }
    else
    {
        cx = x.data & D.MASK_COE1;
        if (cx == 0U)
            return FastClass.zero;
        ex = cast(uint)((x.data.hi & D.MASK_EXP1.hi) >>> (D.SHIFT_EXP1 - 64)) - D.EXP_BIAS;
    }

    return FastClass.finite;
}

ExceptionFlags decimalInc(D)(ref D x, const int precision, const RoundingMode mode)
{

    DataType!D cx; int ex; bool sx;
    switch(fastDecode(x, cx, ex, sx))
    {
        case FastClass.signalingNaN:
            return ExceptionFlags.invalidOperation;
        case FastClass.quietNaN:
        case FastClass.infinite:
            return ExceptionFlags.none;
        case FastClass.zero:
            x = D.one;
            return ExceptionFlags.none;
        default:
            flags = coefficientAdd(cx, ex, sx, T(1U), 0, false, RoundingMode.implicit);
            return x.adjustedPack(cx, ex, sx, precision, mode, flags);
    }
}

ExceptionFlags decimalDec(D)(ref D x, const int precision, const RoundingMode mode)
{
    DataType!D cx; int ex; bool sx;
    switch(fastDecode(x, cx, ex, sx))
    {
        case FastClass.signalingNaN:
            return ExceptionFlags.invalidOperation;
        case FastClass.quietNaN:
        case FastClass.infinite:
            return ExceptionFlags.none;
        case FastClass.zero:
            x = -D.one;
            return ExceptionFlags.none;
        default:
            flags = coefficientAdd(cx, ex, sx, T(1U), 0, true, RoundingMode.implicit);
            return x.adjustedPack(cx, ex, sx, precision, mode, flags);
    }
}

ExceptionFlags decimalRound(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    DataType!D cx; int ex; bool sx;
    switch(fastDecode(x, cx, ex, sx))
    {
        case FastClass.signalingNaN:
            return ExceptionFlags.invalidOperation; 
        case FastClass.quietNaN:
        case FastClass.infinite:
        case FastClass.zero:
            return ExceptionFlags.none;
        default:
            auto flags = coefficientAdjust(cx, ex, 0, D.EXP_MAX, D.COEF_MAX, sx, mode);
            return x.adjustedPack(cx, ex, sx, precision, mode, flags);
    }
}

ExceptionFlags decimalAdjust(D)(ref D x, const int precision, const RoundingMode mode)
{
    DataType!D cx; int ex; bool sx;
    switch(fastDecode(x, cx, ex, sx))
    {
        case FastClass.signalingNaN:
            return ExceptionFlags.invalidOperation; 
        case FastClass.quietNaN:
        case FastClass.infinite:
        case FastClass.zero:
            return ExceptionFlags.none;
        default:
            return x.adjustedPack(cx, ex, sx, precision, mode, ExceptionFlags.none);
    }
}

ExceptionFlags decimalNextUp(D)(ref D x)
if (isDecimal!D)
{
    DataType!D cx; int ex; bool sx;
    switch(fastDecode(x, cx, ex, sx))
    {
        case FastClass.signalingNaN:
            return ExceptionFlags.invalidOperation; 
        case FastClass.quietNaN:
            return ExceptionFlags.none;
        case FastClass.infinite:
            if (sx)
                x = -D.max;
            return ExceptionFlags.none;
        case FastClass.zero:
            x.pack(DataType!D(1U), D.EXP_MIN, false);
            return ExceptionFlags.none;
        default:
            if (sx)
            {
                if (coefficient == 1U)
                {
                    coefficient = 10U;
                    --exponent;
                }
                --coefficient;
            }
            else
                ++coefficient;
            return x.adjustedPack(cx, ex, sx, precision, mode, ExceptionFlags.none);
    }  
}

ExceptionFlags decimalNextDown(D)(ref D x)
if (isDecimal!D)
{
    DataType!D cx; int ex; bool sx;
    switch(fastDecode(x, cx, ex, sx))
    {
        case FastClass.signalingNaN:
            return ExceptionFlags.invalidOperation; 
        case FastClass.quietNaN:
            return ExceptionFlags.none;
        case FastClass.infinite:
            if (!sx)
                x = D.max;
            return ExceptionFlags.none;
        case FastClass.zero:
            x.pack(DataType!D(1U), D.EXP_MIN, true);
            return ExceptionFlags.none;
        default:
            if (!sx)
            {
                if (coefficient == 1U)
                {
                    coefficient = 10U;
                    --exponent;
                }
                --coefficient;
            }
            else
                ++coefficient;
            return x.adjustedPack(cx, ex, sx, precision, mode, ExceptionFlags.none);
    }
}

ExceptionFlags decimalMin(D1, D2, D)(auto const ref D1 x, auto const ref D2 y, out D z)
if (isDecimal!(D1, D2, D) && is(D: CommonDecimal!(D1, D2)))
{
    DataType!D cx, cy; int ex, ey; bool sx, sy;
    immutable fx = fastDecode(x, cx, ex, sx);
    immutable fy = fastDecode(y, cy, ey, sy);

    if (fx == FastClass.signalingNaN)
    {
        z = x;
        return ExceptionFlags.invalidOperation;
    }

    if (fy == FastClass.signalingNaN)
    {
        z = y;
        return ExceptionFlags.invalidOperation;
    }

    if (fx == FastClass.quietNaN)
    {
        z = y;
        return ExceptionFlags.none;
    }

    if (fy == FastClass.quietNaN)
    {
        z = x;
        return ExceptionFlags.none;
    }

    immutable c = coefficientCmp(cx, ex, sx, cy, ey, sy);
    if (c >= 0)
        z = y;
    else
        z = x;

    return ExceptionFlags.none;
}

ExceptionFlags decimalMinAbs(D1, D2, D)(auto const ref D1 x, auto const ref D2 y, out D z)
if (isDecimal!(D1, D2, D) && is(D: CommonDecimal!(D1, D2)))
{
    DataType!D cx, cy; int ex, ey; bool sx, sy;
    immutable fx = fastDecode(x, cx, ex, sx);
    immutable fy = fastDecode(y, cy, ey, sy);

    if (fx == FastClass.signalingNaN)
    {
        z = x;
        return ExceptionFlags.invalidOperation;
    }

    if (fy == FastClass.signalingNaN)
    {
        z = y;
        return ExceptionFlags.invalidOperation;
    }

    if (fx == FastClass.quietNaN)
    {
        z = y;
        return ExceptionFlags.none;
    }

    if (fy == FastClass.quietNaN)
    {
        z = x;
        return ExceptionFlags.none;
    }

    immutable c = coefficientCmp(cx, ex, cy, ey);
    if (c >= 0)
        z = y;
    else
        z = x;

    return ExceptionFlags.none;
}

ExceptionFlags decimalMax(D1, D2, D)(auto const ref D1 x, auto const ref D2 y, out D z)
if (isDecimal!(D1, D2, D) && is(D: CommonDecimal!(D1, D2)))
{
    DataType!D cx, cy; int ex, ey; bool sx, sy;
    immutable fx = fastDecode(x, cx, ex, sx);
    immutable fy = fastDecode(y, cy, ey, sy);

    if (fx == FastClass.signalingNaN)
    {
        z = x;
        return ExceptionFlags.invalidOperation;
    }

    if (fy == FastClass.signalingNaN)
    {
        z = y;
        return ExceptionFlags.invalidOperation;
    }

    if (fx == FastClass.quietNaN)
    {
        z = y;
        return ExceptionFlags.none;
    }

    if (fy == FastClass.quietNaN)
    {
        z = x;
        return ExceptionFlags.none;
    }

    immutable c = coefficientCmp(cx, ex, sx, cy, ey, sy);
    if (c <= 0)
        z = y;
    else
        z = x;

    return ExceptionFlags.none;
}

ExceptionFlags decimalMaxAbs(D1, D2, D)(auto const ref D1 x, auto const ref D2 y, out D z)
if (isDecimal!(D1, D2, D) && is(D: CommonDecimal!(D1, D2)))
{
    DataType!D cx, cy; int ex, ey; bool sx, sy;
    immutable fx = fastDecode(x, cx, ex, sx);
    immutable fy = fastDecode(y, cy, ey, sy);

    if (fx == FastClass.signalingNaN)
    {
        z = x;
        return ExceptionFlags.invalidOperation;
    }

    if (fy == FastClass.signalingNaN)
    {
        z = y;
        return ExceptionFlags.invalidOperation;
    }

    if (fx == FastClass.quietNaN)
    {
        z = y;
        return ExceptionFlags.none;
    }

    if (fy == FastClass.quietNaN)
    {
        z = x;
        return ExceptionFlags.none;
    }

    immutable c = coefficientCmp(cx, ex, cy, ey);
    if (c <= 0)
        z = y;
    else
        z = x;

    return ExceptionFlags.none;
}



ExceptionFlags decimalQuantize(D1, D2)(ref D1 x, auto const ref D2 y, const int precision, const RoundingMode mode)
if (isDecimal!(D1, D2))
{
    if (isSignaling(x) || isSignaling(y))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }
    else if (isNaN(x) || isNaN(y))
    {
        x = D.nan;
        return ExceptionFlags.none;
    }
    else if (isInfinity(x))
    {
        if (!isInfinity(y))
        {
            x = D.nan;
            return ExceptionFlags.invalidOperation;
        }
        return ExceptionFlags.none;
    }
    else if (isInfinity(y))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }
    else
    {
        DataType!D1 cx;
        DataType!D2 cy;
        int ex, ey;
        bool sx = x.unpack(cx, ex);
        y.unpack(cy, ey);
        return x.adjustedPack(cx, ey, sx, precision, mode, ExceptionFlags.none);
    }   
}

ExceptionFlags decimalScale(D)(ref D x, const int n, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isInfinity(x) || isZero(x) || isNaN(x))
        return ExceptionFlags.none;

    if (n == 0)
        return ExceptionFlags.none;
    

    DataType!D coefficient;
    int exponent;
    bool isNegative = x.unpack(coefficient, exponent);

    if (n < 0)
        coefficientShrink(coefficient, exponent);
    else
    {
        int target = 100;
        coefficientExpand(coefficient, exponent, target);
    }

    cappedAdd(exponent, n);
    
    return x.adjustedPack(coefficient, exponent, isNegative, precision, mode, ExceptionFlags.none);
    
}

ExceptionFlags decimalLog(D)(auto const ref D x, out int y)
{
    if (isNaN(x))
    {
        y = int.min;
        return ExceptionFlags.invalidOperation;
    }

    if (isInfinity(x))
    {
        y = int.min + 1;
        return ExceptionFlags.invalidOperation;
    }

    if (isZero(x))
    {
        y = int.min + 2;
        return ExceptionFlags.invalidOperation;
    }

    DataType!D c; int e;
    x.unpack(c, e);
    y = prec(c) + e - 1;
    return ExceptionFlags.none;
}

@safe pure nothrow @nogc
D canonical(D)(auto const ref D x)
if (isDecimal!D)
{
    Unqual!D result = x;
    if ((result.data & D.MASK_INF) == D.MASK_INF)
    {
        if ((result.data & D.MASK_QNAN) == D.MASK_QNAN &&
            (result.data & D.MASK_PAYL) > D.PAYL_MAX)
            result.data &= D.MASK_SNAN | D.MASK_SGN;
        else
            result.data &= D.MASK_INF | D.MASK_SGN;
    }
    else if ((result.data & D.MASK_EXT) == D.MASK_EXT && 
             (((result.data & D.MASK_COE2) | D.MASK_COEX) > D.COEF_MAX))
        result.data = D.MASK_ZERO;    
    return result;
}


ExceptionFlags decimalMul(D1, D2)(ref D1 x, auto const ref D2 y, const int precision, const RoundingMode mode)
if (isDecimal!(D1, D2))
{
    bool sx = cast(bool)signbit(x);
    bool sy = cast(bool)signbit(y);

    if (isSignaling(x) || isSignaling(y))
    {
        x = sx ^ sy ? -D1.nan : D1.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x) || isNaN(y))
    {
        x = sx ^ sy ? -D1.nan : D1.nan;
        return ExceptionFlags.none;
    }

    if (isInfinity(x))
    {
        if (isZero(y))
        {
            x = sx ^ sy ? -D1.nan : D1.nan;
            return ExceptionFlags.invalidOperation;
        }
        x = sx ^ sy ? -D1.infinity : D1.infinity;
        return ExceptionFlags.none;
    }

    if (isInfinity(y))
    {
        if (isZero(x))
        {
            x = sx ^ sy ? -D1.nan : D1.nan;
            return ExceptionFlags.invalidOperation;
        }
        x = sx ^ sy ? -D1.infinity : D1.infinity;
        return ExceptionFlags.none;
    }

    if (isZero(x) || isZero(y))
    {
        x = sx ^ sy ? -D1.zero : D1.zero;
        return ExceptionFlags.none;
    }

    alias T1 = DataType!D1;
    alias T2 = DataType!D2;

    T1 cx;
    T2 cy;
    int ex, ey;
    x.unpack(cx, ex);
    y.unpack(cy, ey);

    static if (D1.sizeof > D2.sizeof)
    {
        T1 cyy = cy;
        alias cxx = cx;
        enum cmax = D1.COEF_MAX;
    }
    else static if (D1.sizeof < D2.sizeof)
    {
        T2 cxx = cx;
        alias cyy = cy;
        T2 cmax = D1.COEF_MAX;
    }
    else
    {
        alias cxx = cx;
        alias cyy = cy;
        enum cmax = D1.COEF_MAX;
    }

    auto flags = coefficientMul(cxx, ex, sx, cyy, ey, sy, mode);
    flags |= coefficientAdjust(cxx, ex, cmax, sx, mode);
    return x.adjustedPack(cvt!T1(cxx), ex, sx, precision, mode, flags);
}

ExceptionFlags decimalMul(D, T)(ref D x, auto const ref T y, const int precision, const RoundingMode mode)
if (isDecimal!D && isIntegral!T)
{
    bool sx = cast(bool)signbit(x);
    static if (isUnsigned!T)
        enum sy = false;
    else
        bool sy = y < 0;

    if (isSignaling(x))
    {
        x = sx ^ sy ? -D.nan : D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
    {
        x = sx ^ sy ? -D.nan : D.nan;
        return ExceptionFlags.none;
    }

    if (isInfinity(x))
    {
        if (!y)
        {
            x = sx ^ sy ? -D.nan : D.nan;
            return ExceptionFlags.invalidOperation;
        }
        x = sx ^ sy ? -D.infinity : D.infinity;
        return ExceptionFlags.none;
    }

    if (isZero(x) || y == 0)
    {
        x = sx ^ sy ? -D.zero : D.zero;
        return ExceptionFlags.none;
    }

    DataType!D cx;
    int ex;
    x.unpack(cx, ex);

    static if (D.sizeof >= T.sizeof)
    {
        DataType!D cy = Unsigned!T(sy ? -y : y);
        alias cxx = cx;
        enum cmax = D.COEF_MAX;
    }
    else
    {
        Unsigned!T cy = sy ? -y : y;
        Unsigned!T cxx = cx;
        Unsigned!T cmax = D.COEF_MAX;
    }

    auto flags = coefficientMul(cxx, ex, sx, cy, 0, sy, mode);
    flags |= coefficientAdjust(cxx, ex, cmax, sx, mode);
    return x.adjustedPack(cvt!(DataType!D)(cxx), ex, sx, precision, mode, flags);
}

ExceptionFlags decimalMul(D, F)(ref D x, auto const ref F y, const int precision, const RoundingMode mode)
if (isDecimal!D && isFloatingPoint!D)
{
    bool sx = cast(bool)signbit(x);
    bool sy = cast(bool)signbit(y);

    if (isSignaling(x))
    {
        x = sx ^ sy ? -D1.nan : D1.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x) || isNaN(y))
    {
        x = sx ^ sy ? -D.nan : D.nan;
        return ExceptionFlags.none;
    }

    if (isInfinity(x))
    {
        if (y == 0.0)
        {
            x = sx ^ sy ? -D.nan : D.nan;
            return ExceptionFlags.invalidOperation;
        }
        x = sx ^ sy ? -D.infinity : D.infinity;
        return ExceptionFlags.none;
    }

    if (isInfinity(y))
    {
        if (isZero(x))
        {
            x = sx ^ xy ? -D.nan : D.nan;
            return ExceptionFlags.invalidOperation;
        }
        x = sx ^ sy ? -D.infinity : D.infinity;
        return ExceptionFlags.none;
    }

    if (isZero(x) || y == 0.0)
    {
        x = sx ^ sy ? -D.zero : D.zero;
        return ExceptionFlags.noe;
    }

    Unqual!D z;
    auto flags = z.packFloatingPoint(f, 0, mode);
    return flags | decimalMul(x, z);
}

ExceptionFlags decimalMul(T, D)(auto const ref T x, auto const ref D y, out D z, const int precision, const RoundingMode mode)
if (isDecimal!D && isIntegral!T)
{
   auto flags = z.packIntegral(x, 0, mode);
   return flags | decimalMul(z, y, precision, mode);
}

ExceptionFlags decimalMul(F, D)(auto const ref F x, auto const ref D y, out D z, const int precision, const RoundingMode mode)
if (isDecimal!D && isFloatingpoint!F)
{
    auto flags = z.packFloatingPoint(x, 0, mode);
    return flags | decimalMul(z, y, precision, mode);
}

ExceptionFlags decimalDiv(D1, D2)(ref D1 x, auto const ref D2 y, const int precision, const RoundingMode mode)
if (isDecimal!(D1, D2))
{
    bool sx = cast(bool)signbit(x);
    bool sy = cast(bool)signbit(y);

    if (isSignaling(x) || isSignaling(y))
    {
        x = sx ^ sy ? -D1.nan : D1.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x) || isNaN(y))
    {
        x = sx ^ sy ? -D1.nan : D1.nan;
        return ExceptionFlags.none;
    }

    if (isInfinity(x))
    {
        if (isZero(y))
        {
            x = sx ^ sy ? -D1.nan : D1.nan;
            return ExceptionFlags.invalidOperation | ExceptionFlags.divisionByZero;
        }

        if (isInfinity(y))
        {
            x = sx ^ sy ? -D1.nan : D1.nan;
            return ExceptionFlags.invalidOperation;
        }
        x = sx ^ sy ? -D1.infinity : D1.infinity;
        return ExceptionFlags.none;
    }

    if (isInfinity(y))
    {
        x = sx ^ sy ? -D1.infinity : D1.infinity;
        return ExceptionFlags.none;
    }

    if (isZero(x))
    {
        x = sx ^ sy ? -D1.zero : D1.zero;
        return ExceptionFlags.none;
    }

    if (isZero(y))
    {
        x = sx ^ sy ? -D1.infinity : D1.infinity;
        return ExceptionFlags.divisionByZero;
    }

    alias T1 = DataType!D1;
    alias T2 = DataType!D2;

    T1 cx;
    T2 cy;
    int ex, ey;

    x.unpack(cx, ex);
    y.unpack(cy, ey);

    static if (D1.sizeof > D2.sizeof)
    {
        T1 cyy = cy;
        alias cxx = cx;
        enum cmax = D1.COEF_MAX;
    }
    else static if (D1.sizeof < D2.sizeof)
    {
        T2 cxx = cx;
        alias cyy = cy;
        T2 cmax = D1.COEF_MAX;
    }
    else
    {
        alias cxx = cx;
        alias cyy = cy;
        enum cmax = D1.COEF_MAX;
    }

    auto flags = coefficientDiv(cxx, ex, sx, cyy, ey, sy, mode);
    flags |= coefficientAdjust(cxx, ex, cmax, sx, mode);
    return x.adjustedPack(cvt!T1(cxx), ex, sx, precision, mode, flags);
}

ExceptionFlags decimalDiv(D, T)(ref D x, auto const ref T y, const int precision, const RoundingMode mode)
if (isDecimal!D && isIntegral!T)
{
    bool sx = cast(bool)signbit(x);
    static if (isUnsigned!T)
        enum sy = false;
    else
        bool sy = y < 0;

    if (isSignaling(x))
    {
        x = sx ^ sy ? -D.nan : D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
    {
        x = sx ^ sy ? -D.nan : D.nan;
        return ExceptionFlags.none;
    }

    if (isInfinity(x))
    {
        if (!y)
        {
            x = sx ^ sy ? -D.nan : D.nan;
            return ExceptionFlags.invalidOperation | ExceptionFlags.divisionByZero;
        }
        x = sx ^ sy ? -D.infinity : D.infinity;
        return ExceptionFlags.none;
    }

    if (isZero(x))
    {
        x = sx ^ sy ? -D.zero : D.zero;
        return ExceptionFlags.none;
    }

    if (!y)
    {
        x = sx ^ sy ? -D.infinity : D.infinity;
        return ExceptionFlags.divisionByZero;
    }


    DataType!D cx;
    int ex;

    x.unpack(cx, ex);

    static if (D.sizeof >= T.sizeof)
    {
        DataType!D cy = Unsigned!T(sy ? -y : y);
        alias cxx = cx;
        enum cmax = D.COEF_MAX;
    }
    else
    {
        Unsigned!T cy = sy ? -y : y;
        Unsigned!T cxx = cx;
        Unsigned!T cmax = D.COEF_MAX;
    }

    auto flags = coefficientDiv(cxx, ex, sx, cy, 0, sy, mode);
    flags |= coefficientAdjust(cxx, ex, cmax, sx, mode);
    return x.adjustedPack(cvt!(DataType!D)(cxx), ex, sx, precision, mode, flags);
}

ExceptionFlags decimalDiv(T, D)(auto const ref T x, auto const ref D y, out D z, const int precision, const RoundingMode mode)
if (isDecimal!D && isIntegral!T)
{
    bool sy = cast(bool)signbit(y);
    static if (isUnsigned!T)
        bool sx = false;
    else
        bool sx = x < 0;

    if (isSignaling(y))
    {
        z = sx ^ sy ? -D.nan : D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(y))
    {
        z = sx ^ sy ? -D.nan : D.nan;
        return ExceptionFlags.none;
    }

    if (isInfinity(y))
    {
        z = sx ^ sy ? -D.infinity : D.infinity;
        return ExceptionFlags.none;
    }

    if (x == 0)
    {
        z = sx ^ sy ? -D.zero : D.zero;
        return ExceptionFlags.none;
    }

    if (isZero(y))
    {
        z = sx ^ sy ? -D.infinity : D.infinity;
        return ExceptionFlags.divisionByZero;
    }



    DataType!D cy;
    int ex, ey;

    y.unpack(cy, ey);

    static if (D.sizeof >= T.sizeof)
    {
        DataType!D cx = sx ? -x : x;
        alias cyy = cy;
        enum cmax = D.COEF_MAX;
    }
    else
    {
        Unsigned!T cx = sx ? -x : x;
        Unsigned!T cyy = cy;
        Unsigned!T cmax = D.COEF_MAX;
    }

    auto flags = coefficientDiv(cx, ex, sx, cyy, ey, sy, mode);
    flags |= coefficientAdjust(cx, ex, cmax, sx, mode);
    return z.adjustedPack(cvt!(DataType!D)(cx), ex, sx, precision, mode, flags);
}

ExceptionFlags decimalDiv(D, F)(ref D x, auto const ref F y, const int precision, const RoundingMode mode)
if (isDecimal!D && isFloatingPoint!D)
{
    bool sx = cast(bool)signbit(x);
    bool sy = cast(bool)signbit(y);

    if (isSignaling(x))
    {
        x = sx ^ sy ? -D.nan : D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x) || isNaN(y))
    {
        x = sx ^ sy ? -D.nan : D.nan;
        return ExceptionFlags.none;
    }

    if (isInfinity(x))
    {
        if (y == 0.0)
        {
            x = sx ^ sy ? -D.nan : D.nan;
            return ExceptionFlags.invalidOperation | ExceptionFlags.divisionByZero;
        }

        if (isInfinity(y))
        {
            x = sx ^ sy ? -D.nan : D.nan;
            return ExceptionFlags.invalidOperation;
        }
        x = sx ^ sy ? -D.infinity : D.infinity;
        return ExceptionFlags.none;
    }

    if (isInfinity(y))
    {
        x = sx ^ sy ? -D.infinity : D.infinity;
        return ExceptionFlags.none;
    }

    if (isZero(x))
    {
        x = sx ^ sy ? -D.zero : D.zero;
        return ExceptionFlags.none;
    }

    if (y == 0.0)
    {
        x = sx ^ sy ? -D.infinity : D.infinity;
        return ExceptionFlags.divisionByZero;
    }

    Unqual!D z;
    auto flags = z.packFloatingPoint(y, f, 0, mode);
    return flags | decimalDiv(x, z, precision, mode);
}

ExceptionFlags decimalDiv(F, D)(auto const ref F x, auto const ref D y, out D z, const int precision, const RoundingMode mode)
if (isDecimal!D && isFloatingPoint!F)
{
    bool sx = cast(bool)signbit(x);
    bool sy = cast(bool)signbit(y);

    if (isSignaling(y))
    {
        z = sx ^ sy ? -D.nan : D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x) || isNaN(y))
    {
        z = sx ^ sy ? -D.nan : D.nan;
        return ExceptionFlags.none;
    }

    if (isInfinity(x))
    {
        if (isZero(y))
        {
            z = sx ^ sy ? -D.nan : D.nan;
            return ExceptionFlags.invalidOperation | ExceptionFlags.divisionByZero;
        }

        if (isInfinity(y))
        {
            z = sx ^ sy ? -D.nan : D.nan;
            return ExceptionFlags.invalidOperation;
        }
        z = sx ^ sy ? -D.infinity : D.infinity;
        return ExceptionFlags.none;
    }

    if (isInfinity(y))
    {
        z = sx ^ sy ? -D.infinity : D.infinity;
        return ExceptionFlags.none;
    }

    if (x == 0.0)
    {
        z = sx ^ sy ? -D.zero : D.zero;
        return ExceptionFlags.none;
    }

    if (isZero(y))
    {
        z = sx ^ sy ? -D.infinity : D.infinity;
        return ExceptionFlags.divisionByZero;
    }

    auto flags = z.packFloatingPoint(f, 0, mode);
    return flags | decimalDiv(z, y, precision, mode);
}

ExceptionFlags decimalAdd(D1, D2)(ref D1 x, auto const ref D2 y, const int precision, const RoundingMode mode)
if (isDecimal!(D1, D2))
{
    bool sx = cast(bool)signbit(x);
    bool sy = cast(bool)signbit(y);

    if (isSignaling(x))
    {
        x = sx ? -D1.nan : D1.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isSignaling(y))
    {
        x = sy ? -D1.nan : D1.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
    {
        x = sx ? -D1.nan : D1.nan;
        return ExceptionFlags.none;
    }

    if (isNaN(y))
    {
        x = sy ? -D1.nan : D1.nan;
        return ExceptionFlags.none;
    }

    if (isInfinity(x))
    {
        if (isInfinity(y))
        {
            if (sx != sy)
            {
                x = sx ? -D1.nan : D1.nan;
                return ExceptionFlags.invalidOperation;
            }
        }
        x = sx ? -D1.infinity : D1.infinity;
        return ExceptionFlags.none;  
    }

    if (isInfinity(y))
    {
        x = sy ? -D1.infinity : D1.infinity;
        return ExceptionFlags.none;   
    }

    if (isZero(x))
        return decimalToDecimal(y, x, precision, mode);

    if (isZero(y))
        return ExceptionFlags.none;

    alias T1 = DataType!D1;
    alias T2 = DataType!D2;

    T1 cx;
    T2 cy;
    int ex, ey;

    x.unpack(cx, ex);
    y.unpack(cy, ey);

    static if (T1.sizeof > T2.sizeof)
    {
        alias cxx = cx;
        T1 cyy = cy;
        enum cmax = D1.COEF_MAX;
    }
    else static if (T1.sizeof < T2.sizeof)
    {
        T2 cxx = cx;
        alias cyy = cy;
        T2 cmax = D1.COEF_MAX;
    }
    else
    {
        alias cxx = cx;
        alias cyy = cy;
        enum cmax = D1.COEF_MAX;
    }

    auto flags = coefficientAdd(cxx, ex, sx, cyy, ey, sy, mode);
    flags |= coefficientAdjust(cxx, ex, cmax, sx, mode);
    return x.adjustedPack(cvt!T1(cxx), ex, sx, precision, mode, flags);
}

ExceptionFlags decimalAdd(D, T)(ref D x, auto const ref T y, const int precision, const RoundingMode mode)
if (isDecimal!D && isIntegral!T)
{
    bool sx = cast(bool)signbit(x);
    static if (isUnsigned!T)
        enum sy = false;
    else
        bool sy = y < 0;

    if (isSignaling(x))
    {
        x = sx ? -D.nan : D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
    {
        x = sx ? -D.nan : D.nan;
        return ExceptionFlags.none;
    }

    if (isInfinity(x))
    {
        x = sx ? -D.infinity : D.infinity;
        return ExceptionFlags.none;  
    }

    if (isZero(x))
        return x.packIntegral(y, precision, mode);

    if (y == 0)
        return ExceptionFlags.none;

    DataType!D cx;
    int ex, ey;

    x.unpack(cx, ex);
    
    static if (D.sizeof >= T.sizeof)
    {
        alias cxx = cx;
        DataType!D cyy = Unsigned!T(sy ? -y : y);
        alias cmax = D.COEF_MAX;
    }
    else
    {
        Unsigned!T cxx = cx;
        Unsigned!T cyy = sy ? -y : y;
        Unsigned!T cmax = D.COEF_MAX;
    }

    auto flags = coefficientAdd(cxx, ex, sx, cyy, ey, sy, mode);
    flags |= coefficientAdjust(cxx, ex, cmax, sx, mode);
    return x.adjustedPack(cvt!(DataType!D)(cxx), ex, sx, precision, mode, flags);
}

ExceptionFlags decimalAdd(D, F)(ref D x, auto const ref F y, const int precision, const RoundingMode mode)
if (isDecimal!D && isFloatingPoint!F)
{
    bool sx = cast(bool)signbit(x);
    bool sy = cast(bool)signbit(y);

    if (isSignaling(x))
    {
        x = sx ? -D.nan : D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
    {
        x = sx ? -D.nan : D.nan;
        return ExceptionFlags.none;
    }

    if (isNaN(y))
    {
        x = sy ? -D.nan : D.nan;
        return ExceptionFlags.none;
    }

    if (isInfinity(x))
    {
        if (isInfinity(y))
        {
            if (sx != sy)
            {
                x = sx ? -D.nan : D.nan;
                return ExceptionFlags.invalidOperation;
            }
        }
        x = sx ? -D.infinity : D.infinity;
        return ExceptionFlags.none;  
    }

    if (isInfinity(y))
    {
        x = sy ? -D.infinity : D.infinity;
        return ExceptionFlags.none;   
    }

    if (isZero(x))
        return x.packFloatingPoint(y, precision, mode);

    if (y == 0.0)
        return ExceptionFlags.none;

    Unqual!D z;
    auto flags = z.packFloatingPoint(f, 0 , mode);
    return decimalAdd(x, z, precision, mode);
}

ExceptionFlags decimalAdd(T, D)(auto const ref T x, auto const ref D y, out D z, const int precision, const RoundingMode mode)
if (isDecimal!D && isIntegral!T)
{
    z = y;
    return decimalAdd(z, x, precision, mode);
}

ExceptionFlags decimalAdd(F, D)(auto const ref F x, ref D y, out D z, const int precision, const RoundingMode mode)
if (isDecimal!D && isFloatingPoint!T)
{
    z = y;
    return decimalAdd(z, x, precision, mode);
}

ExceptionFlags decimalSub(D1, D2)(ref D1 x, auto const ref D2 y, const int precision, const RoundingMode mode)
if (isDecimal!(D1, D2))
{
   return decimalAdd(x, -y, precision, mode);
}

ExceptionFlags decimalSub(D, T)(ref D x, auto const ref T y, const int precision, const RoundingMode mode)
if (isDecimal!D && isIntegral!T)
{
    bool sx = cast(bool)signbit(x);
    static if (isUnsigned!T)
        enum sy = false;
    else
        bool sy = y < 0;

    if (isSignaling(x))
    {
        x = sx ? -D.nan : D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
    {
        x = sx ? -D.nan : D.nan;
        return ExceptionFlags.none;
    }

    if (isInfinity(x))
    {
        x = sx ? -D.infinity : D.infinity;
        return ExceptionFlags.none;  
    }

    if (isZero(x))
    {
        auto flags = x.packIntegral(y, D.realPrecision(precision), mode);
        x = -x;
        return flags;
    }

    if (y == 0)
        return ExceptionFlags.none;

    DataType!D cx;
    int ex, ey;

    x.unpack(cx, ex);

    static if (D.sizeof >= T.sizeof)
    {
        alias cxx = cx;
        DataType!D cyy = Unsigned!T(sy ? -y : y);
        alias cmax = D.COEF_MAX;
    }
    else
    {
        Unsigned!T cxx = cx;
        Unsigned!T cyy = sy ? -y : y;
        Unsigned!T cmax = D.COEF_MAX;
    }

    auto flags = coefficientAdd(cxx, ex, sx, cyy, ey, !sy, mode);
    flags |= coefficientAdjust(cxx, ex, cmax, sx, mode);
    return x.adjustedPack(cvt!(DataType!D)(cxx), ex, sx, precision, mode, flags);
}

ExceptionFlags decimalSub(D, F)(ref D x, auto const ref F y, const int precision, const RoundingMode mode)
if (isDecimal!D && isFloatingPoint!F)
{
    return decimalAdd(x, -y, precision, mode);
}

ExceptionFlags decimalSub(T, D)(auto const ref T x, auto const ref D y, out D z, const int precision, const RoundingMode mode)
if (isDecimal!D && isIntegral!T)
{
    static if (isUnsigned!T)
        enum sx = false;
    else
        bool sx = x < 0;
    bool sy = cast(bool)signbit(y);
    

    if (isSignaling(y))
    {
        z = sy ? -D.nan : D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(y))
    {
        z = sx ? -D.nan : D.nan;
        return ExceptionFlags.none;
    }

    if (isInfinity(y))
    {
        z = sy ? -D.infinity : D.infinity;
        return ExceptionFlags.none;  
    }

    if (isZero(y))
        return z.packIntegral(x, D.realPrecision(precision), mode);

    if (x == 0)
    {
        z = -y;
        return ExceptionFlags.none;
    }

    DataType!D cy;
    int ex, ey;

    y.unpack(cy, ey);

    static if (D.sizeof >= T.sizeof)
    {
        alias cyy = cy;
        DataType!D cxx = sx ? -x : x;
    }
    else
    {
        Unsigned!T cyy = cy;
        Unsigned!T cxx = sx ? -x : x;
    }

    auto flags = coefficientAdd(cxx, ex, sx, cyy, ey, !sy, mode);
    flags |= coefficientAdjust(cxx, ex, cmax, sx, mode);
    return x.adjustedPack(cvt!(DataType!D)(cxx), ex, sx, precision, mode, flags);
}

ExceptionFlags decimalSub(F, D)(auto const ref F x, auto const ref D y, out D z, const int precision, const RoundingMode mode)
if (isDecimal!D && isFloatingPoint!D)
{
    z = -y;
    return decimalAdd(z, x, precision, mode);
}

ExceptionFlags decimalMod(D1, D2)(ref D1 x, auto const ref D2 y, const int precision, const RoundingMode mode)
if (isDecimal!(D1, D2))
{
    bool sx = cast(bool)signbit(x);
    bool sy = cast(bool)signbit(y);

    ExceptionFlags flags;

    if (isSignaling(x))
    {
        x = sx ? -D1.nan : D1.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isSignaling(y))
    {
        x = sy ? -D1.nan : D1.nan;
        return ExceptionFlags.invalidOperation;
    }
    
    if (isNaN(x))
    {
        x = sx ? -D1.nan : D1.nan;
        return ExceptionFlags.none;
    }

    if (isNaN(y))
    {
        x = sy ? -D1.nan : D1.nan;
        return ExceptionFlags.none;
    }

    if (isInfinity(x) || isZero(y))
    {
        x = sx ? -D1.nan : D1.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isInfinity(y))
        return ExceptionFlags.none;
    
    alias T1 = DataType!D1;
    alias T2 = DataType!D2;

    T1 cx;
    T2 cy;
    int ex, ey;

    x.unpack(cx, ex);
    y.unpack(cy, ey);

    static if (D1.sizeof > D2.sizeof)
    {
        T1 cyy = cy;
        alias cxx = cx;
        enum cmax = D1.COEF_MAX;
    }
    else static if (D1.sizeof < D2.sizeof)
    {
        T2 cxx = cx;
        alias cyy = cy;
        T2 cmax = D1.COEF_MAX;
    }
    else
    {
        alias cxx = cx;
        alias cyy = cy;
        alias cmax = D1.COEF_MAX;
    }

    flags = coefficientMod(cxx, ex, sx, cyy, ey, sy, mode);
    flags |= coefficientAdjust(cxx, ex, cmax, sx, mode);
    return x.adjustedPack(cvt!T1(cxx), ex, sx, precision, mode, flags);

}

ExceptionFlags decimalMod(D, T)(ref D x, auto const ref T y, const int precision, const RoundingMode mode)
if (isDecimal!D && isIntegral!T)
{
    bool sx = cast(bool)signbit(x);
    static if (isUnsigned!T)
        enum sy = false;
    else
        bool sy = y < 0;

    if (isSignaling(x))
    {
        x = sx ? -D.nan : D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
    {
        x = sx ? -D.nan : D.nan;
        return ExceptionFlags.none;
    }

    if (isInfinity(x) || y == 0)
    {
        x = sx ? -D.nan : D.nan;
        flags = ExceptionFlags.invalidOperation;
    }
    DataType!D cx;
    int ex, ey;

    x.unpack(cx, ex);

    static if (D.sizeof >= T.sizeof)
    {
        alias cxx = cx;
        DataType!D cyy = sy ? -y : y;
    }
    else
    {
        Unsigned!T cxx = cx;
        Unsigned!T cyy = sy ? -y : y;
    }

    auto flags = coefficientMod(cxx, ex, sx, cyy, ey, sy, mode);
    flags |= coefficientAdjust(cxx, ex, cmax, sx, mode);
    return x.adjustedPack(cvt!(DataType!D)(cxx), ex, sx, precision, mode, flags);

}

ExceptionFlags decimalMod(T, D)(auto const ref T x, auto const ref D y, out D z, const int precision, const RoundingMode mode)
if (isDecimal!D && isIntegral!T)
{
    static if (isUnsigned!T)
        enum sx = false;
    else
        bool sx = x < 0;
    bool sy = cast(bool)signbit(y);
    

    if (isSignaling(y))
    {
        z = sy ? -D.nan : D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(y))
    {
        z = sy ? -D.nan : D.nan;
        return ExceptionFlags.none;
    }

    if (isZero(y))
    {
        z = sy ? -D.nan : D.nan;
        flags = ExceptionFlags.invalidOperation;
    }

    if (isInfinity(y))
        return ExceptionFlags.none;

    DataType!D cy;
    int ex, ey;

    y.unpack(cy, ey);

    static if (D.sizeof >= T.sizeof)
    {
        alias cyy = cy;
        DataType!D cxx = sx ? -x : x;
        alias cmax = D.COEF_MAX;
    }
    else
    {
        Unsigned!T cyy = cy;
        Unsigned!T cxx = sx ? -x : x;
        Unsigned!T cmax = D.COEFMAX;
    }

    auto flags = coefficientMod(cxx, ex, sx, cyy, ey, sy, mode);
    flags |= coefficientAdjust(cxx, ex, cmax, sx, mode);
    return z.adjustedPack(cvt!(DataType!D)(cxx), ex, sx, precision, mode, flags);
    return flags;

}

ExceptionFlags decimalMod(D, F)(ref D x, auto const ref F y, const int precision, const RoundingMode mode)
if (isDecimal!D && isFloatingPoint!D)
{
    bool sx = cast(bool)signbit(x);
    bool sy = cast(bool)signbit(y);

    if (isSignaling(x))
    {
        x = sx ? -D.nan : D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
    {
        x = sx ? -D.nan : D.nan;
        return ExceptionFlags.none;
    }

    if (isNaN(y))
    {
        x = sy ? -D.nan : D.nan;
        return ExceptionFlags.none;
    }

    if (isInfinity(x) || y == 0.0)
    {
        x = sx ? -D.nan : D.nan;
        flags = ExceptionFlags.invalidOperation;
    }

    if (isInfinity(y))
        return ExceptionFlags.none;

    real f;
    auto flags = decimalToFloat(x, f, mode);
    f %= y;
    flags |= x.packFloatingPoint(f, precision, mode);
    return flags;
}

ExceptionFlags decimalMod(F, D)(auto const ref F x, auto const ref D y, out D z, const int precision, const RoundingMode mode)
if (isDecimal!D && isFloatingPoint!F)
{
    bool sx = cast(bool)signbit(x);
    bool sy = cast(bool)signbit(y);

    if (isSignaling(y))
    {
        x = sy ? -D.nan : D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
    {
        x = sx ? -D.nan : D.nan;
        return ExceptionFlags.none;
    }

    if (isNaN(y))
    {
        x = sy ? -D.nan : D.nan;
        return ExceptionFlags.none;
    }

    if (isInfinity(x) || isZero(y))
    {
        x = sx ? -D.nan : D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isInfinity(y))
        return ExceptionFlags.none;

    auto flags = z.packFloatingPoint(x, 0, mode);
    return flags | decimalMod(z, y, precision, mode);

}

int decimalCmp(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!(D1, D2))
{



    if (isNaN(x) || isNaN(y))
        return -2;
    
    bool sx = cast(bool)signbit(x);
    bool sy = cast(bool)signbit(y);

    if (isZero(x))
    {
        if (isZero(y))
            return 0;
        return sy ? 1 : -1;
    }

    if (isZero(y))
        return sx ? -1 : 1;

    if (sx != sy)
        return sx ? -1 : 1;

    if (isInfinity(x))
    {
        if (isInfinity(y))
            return 0;
        return sx ? -1 : 1;
    }

    if (isInfinity(y))
        return sy ? 1 : -1;
       
    alias T1 = DataType!D1;
    alias T2 = DataType!D2;

    T1 cx;
    T2 cy;
    int ex, ey;

    x.unpack(cx, ex);
    y.unpack(cy, ey);

    static if (D1.sizeof > D2.sizeof)
    {
        T1 cyy = cy;
        alias cxx = cx;
    }
    else static if (D1.sizeof < D2.sizeof)
    {
        T2 cxx = cx;
        alias cyy = cy;
    }
    else
    {
        alias cxx = cx;
        alias cyy = cy;
    }

    return coefficientCmp(cxx, ex, sx, cyy, ey, sy);

}

int decimalCmp(D, T)(auto const ref D x, auto const ref T y)
if (isDecimal!D && isIntegral!T)
{
    if (isNaN(x))
        return -2;

    bool sx = cast(bool)signbit(x);
    static if (isUnsigned!T)
        enum sy = false;
    else
        bool sy = y < 0;

    if (isZero(x))
    {
        if (y == 0)
            return 0;
        return sy ? 1 : -1;
    }

    if (y == 0)
        return sx ? -1 : 1;

    if (sx != sy)
        return sx ? -1 : 1;

    if (isInfinity(x))
        return sx ? -1 : 1;

    DataType!D cx;
    int ex, ey;

    x.unpack(cx, ex);

    static if (D.sizeof >= T.sizeof)
    {
        alias cxx = cx;
        DataType!D cyy = sy ? -y : y;
    }
    else
    {
        Unsigned!T cxx = cx;
        Unsigned!T cyy = sy ? -y : y;
    }

    return cmp(cxx, ex, sx, cyy, ey, sy);

}

int decimalCmp(D, F)(auto const ref D x, auto const  ref F y)
if (isDecimal!D && isFloatingPoint!F)
{

    if (isNaN(x) || isNaN(y))
        return -2;

    bool sx = cast(bool)signbit(x);
    bool sy = cast(bool)signbit(y);

    if (isZero(x))
    {
        if (y == 0.0)
            return 0;
        return sy ? 1 : -1;
    }

    if (y == 0.0)
        return sx ? -1 : 1;

    if (sx != sy)
        return sx ? -1 : 1;

    if (isInfinity(x))
    {
        if (isInfinity(y))
            return 0;
        return sx ? -1 : 1;
    }

    if (isInfinity(y))
        return sx ? 1 : -1;

    Unqual!D v = void;

    auto flags = v.packFloatingPoint(y, D.PRECISION, RoundingMode.towardZero);

    if (flags & ExceptionFlags.overflow)
    {
        //floating point is too big
        return sx ? 1 : -1;
    }
    else if (flags & ExceptionFlags.underflow)
    {
        //floating point is too small
        return sx ? -1 : 1;
    }

    auto result = cmp(x, v);

    if (result == 0 && (flags & ExceptionFlags.inexact))
    {
        //seems equal, but float was truncated toward zero, so it's smaller
        return sx ? -1 : 1;
    }

    return result;
}

bool decimalEqu(D1, D2)(auto const ref D1 x, auto const ref D2 y)
if (isDecimal!(D1, D2))
{
    if (isNaN(x) || isNaN(y))
        return false;

    bool sx = cast(bool)signbit(x);
    bool sy = cast(bool)signbit(y);

    if (isZero(x))
        return isZero(y);

    if (isZero(y))
        return false;

    if (sx != sy)
        return false;

    if (isInfinity(x))
        return isInfinity(y);

    if (isInfinity(y))
        return false; 

    alias T1 = DataType!D1;
    alias T2 = DataType!D2;

    T1 cx;
    T2 cy;
    int ex, ey;

    x.unpack(cx, ex);
    y.unpack(cy, ey);

    static if (D1.sizeof > D2.sizeof)
    {
        T1 cyy = cy;
        alias cxx = cx;
    }
    else static if (D1.sizeof < D2.sizeof)
    {
        T2 cxx = cx;
        alias cyy = cy;
    }
    else
    {
        alias cxx = cx;
        alias cyy = cy;
    }

    return coefficientEqu(cxx, ex, sx, cyy, ey, sy);

}

bool decimalEqu(D, T)(auto const ref D x, auto const ref T y)
if (isDecimal!D && isIntegral!T)
{
    if (isNaN(x))
        return false;

    bool sx = cast(bool)signbit(x);
    static if (isUnsigned!T)
        enum sy = false;
    else
        bool sy = y < 0;

    if (isZero(x))
        return y == 0;

    if (y == 0)
        return false;

    if (sx != sy)
        return false;

    if (isInfinity(x))
        return false;

    DataType!D cx;
    int ex, ey;

    x.unpack(cx, ex);

    static if (D.sizeof >= T.sizeof)
    {
        alias cxx = cx;
        DataType!D cyy = cast(Unsigned!T)(sy ? -y : y);
    }
    else
    {
        Unsigned!T cxx = cx;
        Unsigned!T cyy = sy ? -y : y;
    }

    return coefficientEqu(cxx, ex, sx, cyy, ey, sy);

}

bool decimalEqu(D, F)(auto const ref D x, auto const  ref F y)
if (isDecimal!D && isFloatingPoint!F)
{

    if (isNaN(x) || isNaN(y))
        return false;

    bool sx = cast(bool)signbit(x);
    bool sy = cast(bool)signbit(y);

    if (isZero(x))
        return y == 0.0;

    if (y == 0.0)
        return false;

    if (sx != sy)
        return false;

    if (isInfinity(x))
        return isInfinity(y);

    if (isInfinity(y))
        return false; 

    Unqual!D v = void;
    auto flags = v.packFloatingPoint(y, D.PRECISION, RoundingMode.towardZero);
    return (!flags && equ(x, v));
}

ExceptionFlags decimalSqrt(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isInfinity(x))
    {
        if (signbit(x))
        {
            x = D.nan;
            return ExceptionFlags.invalidOperation;
        }
        return ExceptionFlags.none;
    }

    if (isZero(x))
        return ExceptionFlags.none;

    if (signbit(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    DataType!D cx;
    int ex;
    x.unpack(cx, ex);

    auto flags = coefficientSqrt(cx, ex);
    return x.adjustedPack(cx, ex, false, precision, mode, flags);
}

ExceptionFlags decimalRsqrt(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isInfinity(x))
    {
        if (signbit(x))
        {
            x = D.nan;
            return ExceptionFlags.invalidOperation;
        }
        return ExceptionFlags.none;
    }

    if (isZero(x))
    {
        x = D.nan;
        return ExceptionFlags.divisionByZero;
    }

    if (signbit(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    Unqual!D y = x;
    auto flags = decimalSqrt(y, 0, mode);
    return flags | decimalDiv(1U, y, x, precision, mode);
}

ExceptionFlags decimalSqr(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    return decimalMul(x, x, precision, mode);
}

ExceptionFlags decimalCbrt(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isInfinity(x))
        return ExceptionFlags.none;

    if (isZero(x))
        return ExceptionFlags.none;

    DataType!D cx;
    int ex;
    bool sx = x.unpack(cx, ex);
    auto flags = coefficientCbrt(cx, ex, sx);
    return x.adjustedPack(cx, ex, sx, precision, mode, flags);
}

ExceptionFlags decimalHypot(D1, D2, D)(auto const ref D1 x, auto const ref D2 y, out D z,
                                    const int precision, const RoundingMode mode)
if (isDecimal!(D1, D2) && is(D: CommonDecimal!(D1, D2)))
{
    if (isSignaling(x) || isSignaling(y))
    {
        z = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x) && isNaN(y))
    {
        z = D.nan;
        return ExceptionFlags.none;
    }

    if (isInfinity(x) || isInfinity(y))
    {
        z = D.infinity;
        return ExceptionFlags.none;
    }

    if (isNaN(x) || isNaN(y))
    {
        z = D.nan;
        return ExceptionFlags.none;
    }

    if (isZero(x))
    {
        z = y;
        return ExceptionFlags.none;
    }

    if (isZero(y))
    {
        z = x;
        return ExceptionFlags.none;
    }

    DataType!D cx, cy;
    int ex, ey;
    x.unpack(cx, ex);
    y.unpack(cy, ey);
    auto flags = coefficientHypot(cx, ex, cy, ey);
    return z.adjustedPack(cx, ex, false, precision, mode, flags);
}

ExceptionFlags decimalFMA(D1, D2, D3, D4)(auto const ref D1 x, auto const ref D2 y, auto const ref D3 z, 
                                      out D4 result, 
                                      const int precision, const RoundingMode mode)
if (isDecimal!(D1, D2, D3) && is(D4 : CommonDecimal!(D1, D2, D3))) 
{
    if (isSignaling(x) || isSignaling(y) || isSignaling(z))
    {
        result = D4.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x) || isNaN(y) || isNaN(z))
    {
        result = D4.nan;
        return ExceptionFlags.none;
    }

    bool sx = cast(bool)signbit(x);
    bool sy = cast(bool)signbit(y);
    bool sz = cast(bool)signbit(z);

    if (isInfinity(x))
    {
        if (isZero(y))
        {
            result = D4.nan;
            return ExceptionFlags.invalidOperation;
        }

        if (isInfinity(z))
        {
            if ((sx ^ sy) != sz)
            {
                result = D4.nan;
                return ExceptionFlags.invalidOperation;
            }
        }
        result = sx ^ sy ? -D4.infinity : D4.infinity;
        return ExceptionFlags.none;
    }

    if (isInfinity(y))
    {
        if (isZero(x))
        {
            result = D4.nan;
            return ExceptionFlags.invalidOperation;
        }

        if (isInfinity(z))
        {
            if ((sx ^ sy) != sz)
            {
                result = D4.nan;
                return ExceptionFlags.invalidOperation;
            }
        }
        result = sx ^ sy ? -D4.infinity : D4.infinity;
        return ExceptionFlags.none;
    }

    if (isZero(x) || isZero(y))
    {
        result = z;
        return ExceptionFlags.none;
    }

    if (isZero(z))
    {
        result = x;
        return decimalMul(result, y, precision, mode);
    }

    DataType!D1 cx;
    DataType!D2 cy;
    DataType!D3 cz;
    int ex, ey, ez;

    x.unpack(cx, ex);
    y.unpack(cy, ey);
    z.unpack(cz, ez);

    static if (D1.sizeof == D4.sizeof)
        alias cxx = cx;
    else
        DataType!D4 cxx = cx;

    static if (D2.sizeof == D4.sizeof)
        alias cyy = cy;
    else
        DataType!D4 cyy = cy;

    static if (D3.sizeof == D4.sizeof)
        alias czz = cz;
    else
        DataType!D4 czz = cz;

    auto flags = coefficientFMA(cxx, ex, sx, cyy, ey, sy, czz, ez, sz, mode);
    return result.adjustedPack(cxx, ex, sx, precision, mode, flags);

}

ExceptionFlags decimalPow(D, T)(ref D x, const T n, const int precision, const RoundingMode mode)
if (isDecimal!D & isIntegral!T)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (!n)
    {
        x = D.one;
        return ExceptionFlags.none;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isInfinity(x))
    {
        x = !signbit(x) || (n & 1) ? D.infinity : -D.infinity;
    }

    if (isZero(x))
    {
        if (n & 1) //odd
        {
            if (n < 0)
            {
                x = signbit(x) ? -D.infinity : D.infinity;
                return ExceptionFlags.divisionByZero;
            }
            else
            {
                x = canonical(x);
                return ExceptionFlags.none;
            }
        }
        else //even
        {
            if (n < 0)
            {
                x = D.infinity;
                return ExceptionFlags.divisionByZero;
            }
            else
            {
                x = D.zero;
                return ExceptionFlags.none;
            }
        }
    }

     if (n == 1)
        return ExceptionFlags.none;


    ExceptionFlags flags;
    Unqual!D v;

    static if (isSigned!T)
    {
        Unsigned!T m = n < 0 ? -n : n;
        

        if (n < 0)
            flags = decimalDiv(1U, x, v, 0, mode);
        else
            v = x;
    }
    else
    {
        Unqual!T m = n;
        v = x;
    }
   
    

    x = 1U;

    ExceptionFlags sqrFlags;

    while (m)
    {
        if (m & 1)
        {
            flags |= sqrFlags | decimalMul(x, v, 0, mode);
            sqrFlags = ExceptionFlags.none; 
        }
        m >>>= 1;
        sqrFlags |= decimalSqr(v, 0, mode);
    }

    return flags | decimalAdjust(x, precision, mode);

}

ExceptionFlags decimalPow(D1, D2)(ref D1 x, auto const ref D2 y, const int precision, const RoundingMode mode)
if (isDecimal!(D1, D2))
{
    long ip;
    auto flags = decimalToSigned(y, ip, 0, mode);
    if (flags == ExceptionFlags.none)
        return decimalPow(x, ip, precision, mode);

    flags = decimalLog(x, 0, mode);
    flags |= decimalMul(x, y, 0, mode);
    return flags | decimalExp(x, precision, mode);
}

ExceptionFlags decimalPow(D, F)(ref D x, auto const ref F y, const int precision, const RoundingMode mode)
if (isDecimal!D && isFloatingPoint!F)
{
    Unqual!D z;
    flags = z.packFloatingPoint(y, 0, mode);
    return flags | decimalPow(x, z, precision, mode);
}

ExceptionFlags decimalPow(T, D)(auto const ref T x, auto const ref D y, out D z, const int precision, const RoundingMode mode)
if (isDecimal!D && isIntegral!T)
{
    flags = z.packIntegral(x, 0, mode);
    return flags | decimalPow(x, y, precision, mode);
}

ExceptionFlags decimalPow(F, D)(auto const ref F x, auto const ref D y, out D z, const int precision, const RoundingMode mode)
if (isDecimal!D && isFloatingPoint!F)
{
    flags = z.packFloatingPoint(x, 0, mode);
    return flags | decimalPow(x, y, precision, mode);
}

ExceptionFlags decimalExp(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isZero(x))
    {
        x = D.one;
        return ExceptionFlags.none;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isInfinity(x))
    {
        x = signbit(x) ? D.zero : D.infinity;
        return ExceptionFlags.none;
    }
 
    long n;
    auto flags = decimalToSigned(x, n, mode);
    if (flags == ExceptionFlags.none)
    {
        x = D.E;
        return decimalPow(x, n, precision, mode);
    }

    static if (is(D : decimal32))
    {
        enum lnmax = decimal32("+223.3507");
        enum lnmin = decimal32("-232.5610");
    }
    else static if (is(D: decimal64))
    {
        enum lnmax = decimal64("+886.4952608027075");
        enum lnmin = decimal64("-916.4288670116301");
    }
    else
    {
        enum lnmax = decimal128("+14149.38539644841072829055748903541");
        enum lnmin = decimal128("-14220.76553433122614449511522413063");
    }   

    if (isLess(x, lnmin))
    {
        x = D.zero;
        return ExceptionFlags.underflow | ExceptionFlags.inexact;
    }

    if (isGreater(x, lnmax))
    {
        x = D.infinity;
        return ExceptionFlags.overflow | ExceptionFlags.inexact;
    }
    
    DataType!D cx;
    int ex;

    bool sx = x.unpack(cx, ex);
    flags = coefficientExp(cx, ex, sx);
    return x.adjustedPack(cx, ex, sx, precision, mode, flags);
}

ExceptionFlags decimalLog(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    if (signbit(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isInfinity(x))
    {
        x = D.infinity;
        return ExceptionFlags.none;
    }

    if (isZero(x))
    {
        x = -D.infinity;
        return ExceptionFlags.divisionByZero;
    }

    DataType!D cx;
    int ex;
    bool sx = x.unpack(cx, ex);
    auto flags = coefficientLog(cx, ex, sx);
    return x.adjustedPack(cx, ex, sx, precision, mode, flags);
}


ExceptionFlags decimalPow(T, D)(auto const ref T x, auto const ref D y, out D result, const int precision, const RoundingMode mode)
if (isDecimal!D && isIntegral!T)
{
    decimal128 r = x;
    auto flags = decimalPow(r, y, precision, mode);
    return flags | decimalToDecimal(r, result);
}

ExceptionFlags decimalPow(F, D)(auto const ref F x, auto const ref D y, out D result, const int precision, const RoundingMode mode)
if (isDecimal!D && isIntegral!T)
{
    decimal128 r = x;
    auto flags = decimalPow(r, y, precision, mode);
    return flags | decimalToDecimal(r, result);
}

ExceptionFlags decimalExp10(D)(out D x, int n, const int precision, const RoundingMode mode)
if (isDecimal!D)
{ 
    if (n == 0)
    {
        x = D.one;
        return ExceptionFlags.none;
    }
    alias T = DataType!D;
    return x.adjustedPack(T(1U), n, false, precision, mode, ExceptionFlags.none);
}

ExceptionFlags decimalExp10(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{ 
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isZero(x))
    {
        x = D.one;
        return ExceptionFlags.none;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isInfinity(x))
    {
        x = signbit(x) ? D.zero : D.infinity;
        return ExceptionFlags.none;
    }
   
    int n;
    auto flags = decimalToSigned(x, n, RoundingMode.implicit);
    if (flags == ExceptionFlags.none)
        return decimalExp10(x, n, precision, mode);

    flags = decimalMul(x, D.LN10, 0, mode);
    return flags | decimalExp(x, precision, mode);
}

ExceptionFlags decimalExp10m1(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{ 
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isZero(x))
        return ExceptionFlags.none;

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isInfinity(x))
    {
        x = signbit(x) ? -D.one : D.infinity;
        return ExceptionFlags.none;
    }

    auto flags = decimalExp10(x, 0, mode);
    return flags | decimalAdd(x, -1, precision, mode);
}


ExceptionFlags decimalExpm1(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isZero(x))
        return ExceptionFlags.none;

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isInfinity(x))
    {
        x = signbit(x) ? -D.one : D.infinity;
        return ExceptionFlags.none;
    }

    auto flags = decimalExp(x, 0, mode);
    return flags | decimalAdd(x, -1, precision, mode);
}

ExceptionFlags decimalExp2(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isZero(x))
    {
        x = D.one;
        return ExceptionFlags.none;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isInfinity(x))
    {
        x = signbit(x) ? D.zero : D.infinity;
        return ExceptionFlags.none;
    }

    int n;
    auto flags = decimalToSigned(x, n, RoundingMode.implicit);
    if (flags == ExceptionFlags.none)
    {
        x = D.two;
        return decimalPow(x, n, precision, mode);
    }

    flags = decimalMul(x, D.LN2, 0, mode);
    return flags | decimalExp(x, precision, mode);
}




ExceptionFlags decimalExp2m1(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isZero(x))
        return ExceptionFlags.none;

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isInfinity(x))
    {
        x = signbit(x) ? -D.one : D.infinity;
        return ExceptionFlags.none;
    }

    auto flags = decimalExp2(x, 0, mode);
    return flags |= decimalAdd(x, -1, precision, mode);
}

ExceptionFlags decimalLog2(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    auto flags = decimalLog(x, 0, mode);
    return flags | decimalDiv(x, D.LN2, precision, mode);
}

ExceptionFlags decimalLog10(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    if (signbit(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isInfinity(x))
    {
        x = D.infinity;
        return ExceptionFlags.none;
    }

    if (isZero(x))
    {
        x = -D.infinity;
        return ExceptionFlags.divisionByZero;
    }

    DataType!D c;
    int e;
    x.unpack(c, e);
    coefficientShrink(c, e);

    Unqual!D y = e;
    flags = decimalMul(y, D.LN10);
    x = c;
    flags |= decimalLog(x, 0, mode);
    return flags | decimalAdd(x, y, precision, mode);
}

ExceptionFlags decimalLogp1(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    auto flags = decimalAdd(x, 1U, 0, mode);
    return flags | decimalLog(x);
}

ExceptionFlags decimalLog2p1(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    auto flags = decimalAdd(x, 1U, 0, mode);
    return flags | decimalLog2(x, precision, mode);
}

ExceptionFlags decimalLog10p1(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    auto flags = decimalAdd(x, 1U, 0, mode);
    return flags | decimalLog10(x, precision, mode);
}

ExceptionFlags decimalCompound(D)(ref D x, const int n, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isLess(x, -D.one))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (n == 0)
    {
        x = D.one;
        return ExceptionFlags.none;
    }

    if (x == -1 && n < 0)
    {
        x = D.infinity;
        return ExceptionFlags.divisionByZero;
    }

    if (x == -1)
    {
        x = D.zero;
        return ExceptionFlags.none;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isInfinity(x))
    {
        if (signbit(x))
            x = n & 1 ? -D.infinity : D.infinity;
        else
            x = D.infinity;
        return ExceptionFlags.none;
    }
    
    Unqual!D y = x;
    auto flags = decimalAdd(x, 1U, 0, mode);
    if ((flags & ExceptionFlags.overflow) && n < 0)
    {
        x = y;
        flags &= ~ExceptionFlags.overflow;
    }

    if (flags & ExceptionFlags.overflow)
        return flags;

    return flags | decimalPow(x, n, precision, mode);
}

ExceptionFlags decimalRoot(D, T)(ref D x, const T n, const int precision, const RoundingMode mode)
if (isDecimal!D && isIntegral!T)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (!n)
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (n == -1)
    {
        return ExceptionFlags.overflow | ExceptionFlags.underflow;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isInfinity(x))
    {
        x = !signbit(x) || (n & 1) ? D.infinity : -D.infinity;
    }

    if (isZero(x))
    {
        if (n & 1) //odd
        {
            if (n < 0)
            {
                x = signbit(x) ? -D.infinity : D.infinity;
                return ExceptionFlags.divisionByZero;
            }
            else
            {
                x = canonical(x);
                return ExceptionFlags.none;
            }
        }
        else //even
        {
            if (n < 0)
            {
                x = D.infinity;
                return ExceptionFlags.divisionByZero;
            }
            else
            {
                x = D.zero;
                return ExceptionFlags.none;
            }
        }
    }

    if (n == 1)
        return ExceptionFlags.none;
    Unqual!D y = 1U;
    auto flags = decimalDiv(y, n, 0, mode);
    return flags | decimalPow(x, y, precision, mode);
}

//reduction at -2pi .. +2pi
ExceptionFlags decimalReduceAngle(D)(ref D x)
if (isDecimal!D)
{
    Unqual!D y = x;
    if (isLessOrEqual(abs(y), D.M_1_2PI))
        return ExceptionFlags.none;

    auto flags = decimalMul(y, D.M_1_2PI);  
    flags |= decimalRound(y, 0, RoundingMode.implicit);      
    flags |= decimalMul(y, D.PI2, 0, RoundingMode.implicit); 
    flags |= decimalAdd(x, -y, 0, RoundingMode.implicit);
    return flags;

}

//reduction at -pi/2 .. +pi/2
ExceptionFlags decimalReduceAngle(D)(ref D x, out int quadrant)
if (isDecimal!D)
{
    auto flags = decimalReduceAngle(x);
    flags |= decimalMul(x, D.M_2_PI, 0, RoundingMode.implicit);
    int factor;
    flags |= decimalToSigned(x, factor, RoundingMode.implicit);
    quadrant = factor % 4 + 1;
    flags |= decimalSub(x, factor, 0, RoundingMode.implicit);
    flags |= decimalMul(x, D.PI_2, 0, RoundingMode.implicit);
    return flags;
}

immutable decimal32[] if32 =
[
    decimal32(s_f2),
    decimal32(s_f3),
    decimal32(s_f4),
    decimal32(s_f5),
    decimal32(s_f6),
    decimal32(s_f7),
    decimal32(s_f8),
    decimal32(s_f9),
    decimal32(s_f10),
];

immutable decimal64[] if64 =
[
    decimal64(s_f2),
    decimal64(s_f3),
    decimal64(s_f4),
    decimal64(s_f5),
    decimal64(s_f6),
    decimal64(s_f7),
    decimal64(s_f8),
    decimal64(s_f9),
    decimal64(s_f10),
    decimal64(s_f11),
    decimal64(s_f12),
    decimal64(s_f13),
    decimal64(s_f14),
    decimal64(s_f15),
    decimal64(s_f16),
    decimal64(s_f17),
    decimal64(s_f18),
];

immutable decimal128[] if128 =
[
    decimal128(s_f2),
    decimal128(s_f3),
    decimal128(s_f4),
    decimal128(s_f5),
    decimal128(s_f6),
    decimal128(s_f7),
    decimal128(s_f8),
    decimal128(s_f9),
    decimal128(s_f10),
    decimal128(s_f11),
    decimal128(s_f12),
    decimal128(s_f13),
    decimal128(s_f14),
    decimal128(s_f15),
    decimal128(s_f16),
    decimal128(s_f17),
    decimal128(s_f18),
    decimal128(s_f19),
    decimal128(s_f20),
    decimal128(s_f21),
    decimal128(s_f22),
    decimal128(s_f23),
    decimal128(s_f24),
    decimal128(s_f25),
    decimal128(s_f26),
    decimal128(s_f27),
    decimal128(s_f28),
    decimal128(s_f29),
    decimal128(s_f30),
    decimal128(s_f31),
];

ExceptionFlags decimalCosQ(D)(ref D x, const int precision, const RoundingMode mode)
{
    //taylor series
    //1 - x2/2! + x4/4! - x6/6! ...

    Unqual!D x2 = x;
    auto flags = decimalSqr(x2, 0, mode);
    x2 = -x2;
    Unqual!D y = 1;
    Unqual!D dividend = 1;
    ulong divisor = 2;
    ulong factor = 2;
    bool overflow;
    do
    {
        x = y;
        flags |= decimalMul(dividend, x2, 0, mode);
        Unqual!D fraction = dividend;
        flags |= decimalDiv(fraction, divisor, 0, mode);
        flags |= decimalAdd(y, fraction, 0, mode);
        divisor = mulu(divisor, ++factor, overflow);
        divisor = mulu(divisor, ++factor, overflow);
    }
    while (!overflow && abs(x - y) > D.epsilon);

    return flags | decimalAdjust(x, precision, mode);
}

ExceptionFlags decimalSinQ(D)(ref D x, const int precision, const RoundingMode mode)
{
    //taylor series
    //x - x3/3! + x5/5! - x7/7! ...

    Unqual!D x2 = x;
    auto flags = decimalSqr(x2, 0, mode);
    x2 = -x2;
    Unqual!D y = x;
    Unqual!D dividend = x;
    ulong divisor = 6;
    ulong factor = 3;
    bool overflow;
    do
    {
        x = y;
        flags |= decimalMul(dividend, x2, 0, mode);
        Unqual!D fraction = dividend;
        flags |= decimalDiv(fraction, divisor, 0, mode);
        flags |= decimalAdd(y, fraction, 0, mode);
        divisor = mulu(divisor, ++factor, overflow);
        divisor = mulu(divisor, ++factor, overflow);
    }
    while (!overflow && abs(x - y) > D.epsilon);

    return flags | decimalAdjust(x, precision, mode);
}

ExceptionFlags decimalSinCosQ(D)(auto const ref D x, out D s, out D c, const int precision, const RoundingMode mode)
{
    Unqual!D cy = 1;
    Unqual!D sy = x;

    Unqual!D dividend = x;
    ulong divisor = 2;
    ulong factor = 2;
    bool overflow;
    ExceptionFlags flags;
    do
    {
        c = cy;
        s = sy;
        flags |= decimalMul(dividend, -x, 0, mode);
        Unqual!D fraction = dividend;
        flags |= decimalDiv(fraction, divisor, 0, mode);
        flags |= decimalAdd(cy, fraction, 0, mode);
        divisor = mulu(divisor, ++factor, overflow);
        if (overflow)
            break;
        flags |= decimalMul(dividend, x, 0, mode);
        fraction = dividend;
        flags |= decimalDiv(fraction, divisor, 0, mode);
        flags |= decimalAdd(sy, fraction, 0, mode);
        divisor = mulu(divisor, ++factor, overflow);
    }
    while (!overflow && (abs(s - sy) > D.epsilon || abs(c - cy) > D.epsilon));

    return flags | decimalAdjust(s, precision, mode) | decimalAdjust(c, precision, mode);
}


ExceptionFlags decimalSin(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isInfinity(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation | ExceptionFlags.underflow;
    }

    if (isNaN(x) || isZero(x))
        return ExceptionFlags.none;
    
    int quadrant;
    auto flags = decimalCapAngle(x, quadrant);

    switch (quadrant)
    {
        case 1:
            flags |= decimalSinQ(x, precision, mode);
            break;
        case 2:
            flags |= decimalCosQ(x, precision, mode);
            break;
        case 3:
            flags |= decimalSinQ(x, precision, mode);
            x = -x;
            break;
        case 4:
            flags |= decimalCosQ(x, precision, mode);
            x = -x;
            break;
        default:
            assert(0);
    }
    return flags;
}

ExceptionFlags decimalCos(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isInfinity(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation | ExceptionFlags.underflow;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isZero(x))
    {
        x = D.one;
        return ExceptionFlags.none;
    }
  
    int quadrant;
    auto flags = decimalCapAngle(x, quadrant);

    switch (quadrant)
    {
        case 1:
            flags |= decimalCosQ(x, precision, mode);
            break;
        case 2:
            flags |= decimalSinQ(x, precision, mode);
            x = -x;
            break;
        case 3:
            flags |= decimalCosQ(x, precision, mode);
            x = -x;
            break;
        case 4:
            flags |= decimalSinQ(x, precision, mode);
            break;
        default:
            assert(0);
    }
    return flags;
}

ExceptionFlags decimalTan(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isInfinity(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation | ExceptionFlags.underflow;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isZero(x))
    {
        return ExceptionFlags.none;
    }

    int quadrant;
    auto flags = decimalCapAngle(x, quadrant);

    Unqual!D s, c;
    flags |= decimalSinCosQ(x, s, c, 0, mode);

    switch(quadrant)
    {
        case 1:
            x = s;
            flags |= decimalDiv(x, c, precision, mode);
            break;
        case 2:
            x = c;
            flags |= decimalDiv(x, -s, precision, mode);
            break;
        case 3:
            x = -s;
            flags |= decimalDiv(x, -c, precision, mode);
            break;
        case 4:
            x = -c;
            flags |= decimalDiv(x, s, precision, mode);
            break;
        default:
            assert(0);
    }
}


immutable decimal32[] im32 =
[
    decimal32(s_m3),
    decimal32(s_m5),
    decimal32(s_m7),
    decimal32(s_m9),
    decimal32(s_m11),
    decimal32(s_m13),
    decimal32(s_m15),
];

immutable decimal64[] im64 =
[
    decimal64(s_m3),
    decimal64(s_m5),
    decimal64(s_m7),
    decimal64(s_m9),
    decimal64(s_m11),
    decimal64(s_m13),
    decimal64(s_m15),
    decimal64(s_m17),
    decimal64(s_m19),
    decimal64(s_m21),
    decimal64(s_m23),
    decimal64(s_m25),
    decimal64(s_m27),
    decimal64(s_m29),
    decimal64(s_m31),
    decimal64(s_m33),
];

immutable decimal128[] im128 =
[
    decimal128(s_m3),
    decimal128(s_m5),
    decimal128(s_m7),
    decimal128(s_m9),
    decimal128(s_m11),
    decimal128(s_m13),
    decimal128(s_m15),
    decimal128(s_m17),
    decimal128(s_m19),
    decimal128(s_m21),
    decimal128(s_m23),
    decimal128(s_m25),
    decimal128(s_m27),
    decimal128(s_m29),
    decimal128(s_m31),
    decimal128(s_m33),
    decimal128(s_m35),
    decimal128(s_m37),
    decimal128(s_m39),
    decimal128(s_m41),
    decimal128(s_m43),
    decimal128(s_m45),
    decimal128(s_m47),
    decimal128(s_m49),
    decimal128(s_m51),
    decimal128(s_m53),
    decimal128(s_m55),
    decimal128(s_m57),
    decimal128(s_m59),
    decimal128(s_m61),
    decimal128(s_m63),
    decimal128(s_m65),
    decimal128(s_m67),
    decimal128(s_m69),
];

ExceptionFlags decimalAtan(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{

    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x) || isZero(x))
        return ExceptionFlags.none;

    if (isInfinity(x))
    {
        x = signbit(x) ? -D.PI_2 : D.PI_2;
        return decimalAdjust(x, precision, mode);
    }

    bool sx = cast(bool)signbit(x);
    x = abs(x);

    if (decimalEqu(x, D.SQRT3))
    {
        x = sx ? -D.PI_3 : D.PI_3;
        return ExceptionFlags.none;
    }
    
    if (decimalEqu(x, D.one))
    {
        x = sx ? -D.PI_4 : D.PI_4;
        return ExceptionFlags.none;
    }

    if (decimalEqu(x, D.M_SQRT3))
    {
        x = sx ? -D.PI_6 : D.PI_6;
        return ExceptionFlags.none;
    }

    /* half angle formula: atan(x/2) = 2 * atan(x/(1 + sqrt(1 +x^^2))))
       reduce x = x / (sqrt(x * x + 1) + 1);

    - if x > sqrt(max), cannot calculate x^^2, but sqrt(1 + x^^2) can safely be assumed is x
      atan(x/2) = 2 * atan(x/(1 + x)). x being so big, x/(1 + x) is in fact very close to 1.
      atan(x/2) = 2 * atan(1) for x > sqrt(max)    
    */
   
    int rfactor = 1;

    ExceptionFlags flags;

    while (x > D.half)
    {
        Unqual!D xp = x;
        flags = decimalSqr(xp, 0, mode);
        if (flags & ExceptionFlags.overflow)
        {
            x = 1U;
            flags &= ~ExceptionFlags.overflow;
        }
        else
        {
            flags |= decimalAdd(xp, 1, 0, mode);
            if (flags & ExceptionFlags.overflow)
            {
                x = 1U;
                flags &= ~ExceptionFlags.overflow;
            }
            else
            {
                flags |= decimalSqrt(xp, 0, mode);
                flags |= decimalAdd(xp, 1, 0, mode);
                flags |= decimalDiv(x, xp, 0, mode);
            }
        }
        rfactor *= 2;
    }


    static if (is(D : decimal32))
        alias im = im32;
    else static if (is(D: decimal64))
        alias im = im64;
    else
        alias im = im128;

    Unqual!D dividend = x;
    Unqual!D xp = x;
    flags |= decimalSqr(xp, 0, mode);
   
    int i = 0;
    while (i < im.length)
    {
        flags |= decimalMul(dividend, -xp, 0, mode);
        Unqual!D factor = dividend;
        flags |= decimalMul(factor, im[i++], 0, mode);
        flags |= decimalAdd(x, factor, 0, mode);
    }
    
    flags |= decimalMul(x, rfactor, 0, mode);

    if (sx)
        x = -x;
    
    return flags | decimalAdjust(x, precision, mode);
}

ExceptionFlags decimalSinPi(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    if (isSignaling(x) || isInfinity(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    decimalReduceAngle(x);

    auto flags = decimalMul(x, D.PI, 0, mode);
    return flags | decimalSin(x, precision, mode);
}

ExceptionFlags decimalCosPi(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    if (isSignaling(x) || isInfinity(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    decimalReduceAngle(x);

    auto flags = decimalMul(x, D.PI, 0, mode);
    return flags | decimalCos(x, precision, mode);
}

ExceptionFlags decimalAtanPi(D)(ref D x, const int precision, const RoundingMode mode)
if (isDecimal!D)
{

    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x) || isZero(x))
        return ExceptionFlags.none;

    if (isInfinity(x))
    {
        x = signbit(x) ? -D.half : D.half;
        return ExceptionFlags.none;
    }

    bool sx = cast(bool)signbit(x);
    x = abs(x);

    if (decimalEqu(x, D.SQRT3))
    {
        x = sx ? -D.onethird : D.onethird;
        return ExceptionFlags.none;
    }

    if (decimalEqu(x, D.one))
    {
        x = sx ? -D.quarter : D.quarter;
        return ExceptionFlags.none;
    }

    if (decimalEqu(x, D.M_SQRT3))
    {
        x = sx ? -D._1_6 : D._1_6;
        return ExceptionFlags.none;
    }


    auto flags = decimalAtan(x, 0, mode);
    return flags | decimalDiv(x, D.PI, precision, mode);
}

ExceptionFlags decimalAtan2(D1, D2, D3)(auto const ref D1 y, auto const ref D2 x, out D3 z, 
                                    const int precision, const RoundingMode mode)
{
    alias D = CommonDecimal!(D1, D2);

    if (isSignaling(x) || isSignaling(y))
    {
        z = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x) || isNaN(y))
    {
        z = D.nan;
        return ExceptionFlags.none;
    }
    
    if (isZero(y))
    {
        if (signbit(x))
            z = signbit(y) ? -D.PI : D.PI;
        else
            z = signbit(y) ? -D.zero : D.zero;
        return ExceptionFlags.inexact;
    }

    if (isZero(x))
    {
        z = signbit(y) ? -D.PI_2 : D.PI_2;
        return ExceptionFlags.inexact;
    }

    if (isInfinity(y))
    {
        if (isInfinity(x))
        {
            if (signbit(x))
                z = signbit(y) ? -D._3PI_4 : D._3PI_4;
            else
                z = signbit(y) ? -D.PI_4 : D.PI_4;
        }
        else
            z = signbit(y) ? -D.PI_2 : D.PI_2;
        return ExceptionFlags.inexact;
    }

    if (isInfinity(x))
    {
        if (signbit(x))
            z = signbit(y) ? -D.PI : D.PI;
        else
            z = signbit(y) ? -D.zero : D.zero;
        return ExceptionFlags.inexact; 
    }

    z = y;
    D xx = x;
    auto flags = decimalDiv(z, xx, 0, mode);
    z = abs(z);
    flags |= decimalAtan(z, 0, mode);
    
    if (signbit(x))
    {
        z = -z;
        return (flags | decimalAdd(z, D.PI, precision, mode)) & ExceptionFlags.inexact;
    }
    else
        return (flags | decimalAdjust(z, precision, mode)) & (ExceptionFlags.inexact | ExceptionFlags.underflow);
}

ExceptionFlags decimalAtan2Pi(D1, D2, D3)(auto const ref D1 y, auto const ref D2 x, out D3 z, const int precision, const RoundingMode mode)
if (isDecimal!(D1, D2, D3))
{
    alias D = CommonDecimal!(D1, D2);

    if (isSignaling(x) || isSignaling(y))
    {
        z = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x) || isNaN(y))
    {
        z = D.nan;
        return ExceptionFlags.none;
    }

    if (isZero(y))
    {
        if (signbit(x))
            z = signbit(y) ? -D.one : D.one;
        else
            z = signbit(y) ? -D.zero : D.zero;
        return ExceptionFlags.inexact;
    }

    if (isZero(x))
    {
        z = signbit(y) ? -D.half : D.half;
        return ExceptionFlags.inexact;
    }

    if (isInfinity(y))
    {
        if (isInfinity(x))
        {
            if (signbit(x))
                z = signbit(y) ? -D.threequarters : D.threequarters;
            else
                z = signbit(y) ? -D.quarter : D.quarter;
        }
        else
            z = signbit(y) ? -D.half : D.half;
        return ExceptionFlags.inexact;
    }

    if (isInfinity(x))
    {
        if (signbit(x))
            z = signbit(y) ? -D.one : D.one;
        else
            z = signbit(y) ? -D.zero : D.zero;
        return ExceptionFlags.inexact; 
    }
    auto flags = decimalAtan2(y, x, z, 0, mode);
    return flags | decimalDiv(z, D.PI, precision, mode);
}

ExceptionFlags decimalAsin(D)(ref D x, const int precision, const RoundingMode mode)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isLess(x, -D.one) || isGreater(x, D.one))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isZero(x))
        return ExceptionFlags.none;
    

    if (x == -D.one)
    {
        x = -D.PI_2;
        return decimalAdjust(x, precision, mode);
    }

    if (x == D.one)
    {
        x = D.PI_2;
        return ExceptionFlags.none;
    }



    if (x == -D.SQRT3_2)
    {
        x = -D.PI_3;
        return ExceptionFlags.none;
    }

    if (x == -D.SQRT2_2)
    {
        x = -D.PI_4;
        return ExceptionFlags.none;
    }

    if (x == -D.half)
    {
        x  = -D.PI_6;
        return ExceptionFlags.none;
    }

    if (x == D.half)
    {
        x  = D.PI_6;
        return ExceptionFlags.none;
    }

    if (x == D.SQRT2_2)
    {
        x = D.PI_4;
        return ExceptionFlags.none;
    }

    if (x == D.SQRT3_2)
    {
        x = D.PI_6;
        return ExceptionFlags.none;
    }

    //asin(x) = 2 * atan(x / ( 1 + sqrt(1 - x* x))
    Unqual!D x2 = x;
    auto flags = decimalSqr(x2, 0, mode);
    x2 = -x2;
    flags |= decimalAdd(x2, 1U, 0, mode);
    flags |= decimalSqrt(x2, 0, mode);
    flags |= decimalAdd(x2, 1U, 0, mode);
    flags |= decimalDiv(x, x2, 0, mode);
    flags |= decimalAtan(x, 0, mode);
    return flags | decimalMul(x, 2U, precision, mode);
}

ExceptionFlags decimalAcos(D)(ref D x, const int precision, const RoundingMode mode)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isLess(x, -D.one) || isGreater(x, D.one))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isZero(x))
    {
        x = D.PI_2;
        return decimalAdjust(x, precision, mode);
    }

    if (x == -D.one)
    {
        x = D.PI;
        return decimalAdjust(x, precision, mode);
    }

    if (x == D.one)
    {
        x = D.zero;
        return ExceptionFlags.none;
    }

    

    if (x == -D.SQRT3_2)
    {
        x = D._5PI_6;
        return ExceptionFlags.none;
    }

    if (x == -D.SQRT2_2)
    {
        x = D._3PI_4;
        return ExceptionFlags.none;
    }

    if (x == -D.half)
    {
        x  = D._2PI_3;
        return ExceptionFlags.none;
    }

    if (x == D.half)
    {
        x  = D.PI_2;
        return ExceptionFlags.none;
    }

    if (x == D.SQRT2_2)
    {
        x = D.PI_4;
        return ExceptionFlags.none;
    }

    if (x == D.SQRT3_2)
    {
        x = D.PI_6;
        return ExceptionFlags.none;
    }

    

    Unqual!D x2 = x;
    auto flags = decimalSqr(x2, 0, mode);
    x2 = -x2;
    flags |= decimalAdd(x2, 1U, 0, mode);
    flags |= decimalSqrt(x2, 0, mode);
    flags |= decimalAdd(x, 1U, 0, mode);
    flags |= decimalDiv(x2, x, 0, mode);
    x = x2;
    flags |= decimalAtan(x, 0, mode);
    return flags | decimalMul(x, 2U, precision, mode);
}

ExceptionFlags decimalSinh(D)(ref D x, const int precision, const RoundingMode mode)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isInfinity(x))
    {
        x = D.infinity;
        return ExceptionFlags.none;
    }

    if (isZero(x))
        return ExceptionFlags.none;

    Unqual!D x1 = x;
    Unqual!D x2 = -x;

    
    auto flags = decimalExp(x1, 0, mode);
    flags |= decimalExp(x2, 0, mode);
    flags |= decimalSub(x1, x2, 0, mode);
    x = x1;
    return flags | decimalMul(x, 2U, precision, mode);
}

ExceptionFlags decimalCosh(D)(ref D x, const int precision, const RoundingMode mode)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isInfinity(x))
    {
        x = D.infinity;
        return ExceptionFlags.none;
    }

    if (isZero(x))
    {
        x = D.one;
        return ExceptionFlags.none;
    }

    Unqual!D x1 = x;
    Unqual!D x2 = -x;
    auto flags = decimalExp(x1, 0, mode);
    flags |= decimalExp(x2, 0, mode);
    flags |= decimalAdd(x1, x2, 0, mode);
    x = x1;
    return flags | decimalMul(x, D.half, precision, mode);
}

ExceptionFlags decimalTanh(D)(ref D x, const int precision, const RoundingMode mode)
{

    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isInfinity(x))
    {
        x = signbit(x) ? -D.one : D.one;
        return ExceptionFlags.none;
    }

    if (isZero(x))
        return ExceptionFlags.none;

    Unqual!D x1 = x;
    Unqual!D x2 = -x;
    auto flags = decimalSinh(x1, 0, mode);
    flags |= decimalCosh(x2, 0, mode);
    x = x1;
    return flags | decimalDiv(x, x2, precision, mode);
}

ExceptionFlags decimalAsinh(D)(ref D x, const int precision, const RoundingMode mode)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x) || isZero(x) || isInfinity(x))
        return ExceptionFlags.none;

    //+- ln(|x| + sqrt(x*x + 1))
    //+-[ln(2) + ln(|x|)] for very big x,

    //sqrt(D.max)/2
    static if (is(D: decimal32))
    {
        enum asinhmax = decimal32("1.581138e51");
    }
    else static if (is(D: decimal64))
    {
        enum asinhmax = decimal64("1.581138830084189e192");
    }
    else
    {
        enum asinhmax = decimal128("1.581138830084189665999446772216359e3072");
    }

    bool sx = cast(bool)signbit(x);
    x = abs(x);

    ExceptionFlags flags;
    if (isGreater(x, asinhmax))
    {
        flags = decimalLog(x, 0, mode) | ExceptionFlags.inexact;
        flags |= decimalAdd(x, D.LN2, 0, mode);
        
    }
    else
    {
        Unqual!D x1 = x;
        flags = decimalSqr(x1, 0, mode);
        flags |= decimalAdd(x1, 1U, 0, mode);
        flags |= decimalSqrt(x1, 0, mode);
        flags |= decimalAdd(x, x1, 0, mode);
        flags |= decimalLog(x, 0, mode);
    }

    if (sx)
        x = -x;
    return flags | decimalAdjust(x, precision, mode);
    
    
}

ExceptionFlags decimalAcosh(D)(ref D x, const int precision, const RoundingMode mode)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x))
        return ExceptionFlags.none;

    if (isLess(x, D.one))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (x == D.one)
    {
        x = D.zero;
        return ExceptionFlags.none;
    }

    if (isInfinity(x))
        return ExceptionFlags.none;

    ExceptionFlags flags;

    /*
        ln(x+sqrt(x*x - 1))
        for very big x: (ln(x + x) = ln(2) + ln(x), otherwise will overflow
    */

    //sqrt(D.max)/2
    static if (is(D: decimal32))
    {
        enum acoshmax = decimal32("1.581138e51");
    }
    else static if (is(D: decimal64))
    {
        enum acoshmax = decimal64("1.581138830084189e192");
    }
    else
    {
        enum acoshmax = decimal128("1.581138830084189665999446772216359e3072");
    }

    if (isGreater(x, acoshmax))
    {
        flags = decimalLog(x, 0, mode) | ExceptionFlags.inexact;
        return flags |= decimalAdd(x, D.LN2, precision, mode);
    }
    else
    {
        Unqual!D x1 = x;
        flags = decimalSqr(x1, 0, mode);
        flags |= decimalSub(x1, 1U, 0, mode);
        flags |= decimalSqrt(x1, 0, mode);
        flags |= decimalAdd(x, x1, 0, mode);
        return flags | decimalLog(x, precision, mode);
    }
}

ExceptionFlags decimalAtanh(D)(ref D x, const int precision, const RoundingMode mode)
{
    if (isSignaling(x))
    {
        x = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (isNaN(x) || isZero(x))
        return ExceptionFlags.none;

    alias T = DataType!D;
    T cx;
    int ex;
    bool sx = x.unpack(cx, ex);

    auto cmp = coefficientCmp(cx, ex, false, T(1U), 0, false);

    if (cmp > 0)
    {
        x = signbit(x) ? -D.nan : D.nan;
        return ExceptionFlags.none;
    }

    if (cmp == 0)
    {
        x = signbit(x) ? -D.infinity : D.infinity;
        return ExceptionFlags.none;
    }
    
    auto flags = coefficientAtanh(cx, ex, sx);
    return x.adjustedPack(cx, ex, sx, precision, mode, flags);

}

ExceptionFlags decimalSum(D)(const(D)[] x, out D result, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    ExceptionFlags flags;
    alias T = MakeUnsigned!(D.sizeof * 16);
    DataType!D cx;
    T cxx, cr;
    int ex, er;
    bool sx, sr;

    result = 0;
    bool hasPositiveInfinity, hasNegativeInfinity;
    size_t i = 0;
    while (i < x.length)
    {
        if (isSignaling(x[i]))
        {
            result = D.nan;
            return ExceptionFlags.invalidOperation;
        }

        if (isNaN(x[i]))
        {
            result = D.nan;
            return ExceptionFlags.none;
        }

        if (isInfinity(x[i]))
        {
            if (signbit(x[i]))
                hasNegativeInfinity = true;
            else
                hasPositiveInfinity = true;
            ++i;
            break;
        }

        if (isZero(x[i]))
        {
            ++i;
            continue;
        }
        
        sx = x.unpack(cx, ex);
        cxx = cx;
        flags |= coefficientAdd(cr, er, sr, cxx, ex, sx, mode);
        ++i;

        if (flags & ExceptionFlags.overflow)
            break;
    }

    while (i < x.length)
    {
        //infinity or overflow detected
        if (isSignaling(x[i]))
        {
            result = D.nan;
            return ExceptionFlags.invalidOperation;
        }

        if (isNaN(x[i]))
        {
            result = D.nan;
            return ExceptionFlags.none;
        }

        if (isInfinity(x[i]))
        {
            if (signbit(x[i]))
                hasNegativeInfinity = true;
            else
                hasPositiveInfinity = true;
        }
        ++i;
    }

    if (hasPositiveInfinity)
    {
        if (hasNegativeInfinity)
        {
            result = D.nan;
            return ExceptionFlags.invalidOperation;
        }
        result = D.infinity;
        return ExceptionFlags.none;
    }

    if (hasNegativeInfinity)
    {
        result = -D.infinity;
        return ExceptionFlags.none;
    }

    flags |= coefficientAdjust(cr, er, cvt!T(DataType!D.max), sr, mode);
    return result.adjustedPack(cvt!(DataType!D)(cr), er, sr, precision, mode, flags);
}

ExceptionFlags decimalSumSquare(D)(const(D)[] x, out D result, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    ExceptionFlags flags;
    alias T = MakeUnsigned!(D.sizeof * 16);
    DataType!D cx;
    T cxx, cr;
    int ex, er;
    bool sr;
    result = 0;
    bool hasInfinity;
    size_t i = 0;
    while (i < x.length)
    {
        if (isSignaling(x[i]))
        {
            result = D.nan;
            return ExceptionFlags.invalidOperation;
        }

        if (isNaN(x[i]))
        {
            result = D.nan;
            return ExceptionFlags.none;
        }

        if (isInfinity(x[i]))
        {
            hasInfinity = true;
            ++i;
            break;
        }

        if (isZero(x[i]))
        {
            ++i;
            continue;
        }

        x.unpack(cx, ex);
        cxx = cx;
        flags |= coefficientSqr(cxx, ex);
        flags |= coefficientAdd(cr, er, sr, cxx, ex, false, mode);
        ++i;

        if (flags & ExceptionFlags.overflow)
            break;
    }

    while (i < x.length)
    {
        //infinity or overflow detected
        if (isSignaling(x[i]))
        {
            result = D.nan;
            return ExceptionFlags.invalidOperation;
        }

        if (isNaN(x[i]))
        {
            result = D.nan;
            return ExceptionFlags.none;
        }

        if (isInfinity(x[i]))
            hasInfinity = true;
        ++i;
    }

    if (hasInfinity)
    {
        result = D.infinity;
        return ExceptionFlags.none;
    }

    flags |= coefficientAdjust(cr, er, cvt!T(DataType!D.max), sr, mode);
    return result.adjustedPack(cvt!(DataType!D)(cr), er, sr, precision, mode, flags);

}

ExceptionFlags decimalSumAbs(D)(const(D)[] x, out D result, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    ExceptionFlags flags;
    alias T = MakeUnsigned!(D.sizeof * 16);
    DataType!D cx;
    T cxx, cr;
    int ex, er;
    bool sr;

    result = 0;
    bool hasInfinity;
    size_t i = 0;
    while (i < x.length)
    {
        if (isSignaling(x[i]))
        {
            result = D.nan;
            return ExceptionFlags.invalidOperation;
        }

        if (isNaN(x[i]))
        {
            result = D.nan;
            return ExceptionFlags.none;
        }

        if (isInfinity(x[i]))
        {
            hasInfinity = true;
            ++i;
            break;
        }

        if (isZero(x[i]))
        {
            ++i;
            continue;
        }

        x.unpack(cx, ex);
        cxx = cx;
        flags |= coefficientAdd(cr, er, sr, cxx, ex, false, mode);
        ++i;

        if (flags & ExceptionFlags.overflow)
            break;
    }

    while (i < x.length)
    {
        //infinity or overflow detected
        if (isSignaling(x[i]))
        {
            result = D.nan;
            return ExceptionFlags.invalidOperation;
        }

        if (isNaN(x[i]))
        {
            result = D.nan;
            return ExceptionFlags.none;
        }

        if (isInfinity(x[i]))
            hasInfinity = true;
        ++i;
    }



    if (hasInfinity)
    {
        result = D.infinity;
        return ExceptionFlags.none;
    }

    flags |= coefficientAdjust(cr, er, cvt!T(DataType!D.max), sr, mode);
    return result.adjustedPack(cvt!(DataType!D)(cr), er, sr, precision, mode, flags);
}

ExceptionFlags decimalDot(D)(const(D)[] x, const(D)[] y, out D result, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    size_t len = x.length;
    if (len > y.length)
        len = y.length;

    bool hasPositiveInfinity, hasNegativeInfinity;

    alias T = MakeUnsigned!(D.sizeof * 16);
    DataType!D cx, cy;
    T cxx, cyy, cr;
    int ex, ey, er;
    bool sx, sy, sr;

    size_t i = 0;
    while (i < len)
    {
        if (isSignaling(x[i]) || isSignaling(y[i]))
        {
            result = D.nan;
            return ExceptionFlags.invalidOperation;
        }

        if (isNaN(x[i]) || isNaN(y[i]))
        {
            result = D.nan;
            return ExceptionFlags.none;
        }

        if (isInfinity(x[i]))
        {
            if (isZero(y[i]))
            {
                result = D.nan;
                return ExceptionFlags.invalidOperation;
            }

            if (isInfinity(y[i]))
            {
                if (signbit(x[i]) ^ signbit(y[i]))
                    hasNegativeInfinity = true;
                else
                    hasPositiveInfinity = true;
                
            }
            else
            {
                if (signbit(x[i]))
                    hasNegativeInfinity = true;
                else
                    hasPositiveInfinity = true;
            }
            ++i;
            break;
        }

        if (isInfinity(y[i]))
        {
            if (isZero(x[i]))
            {
                result = D.nan;
                return ExceptionFlags.invalidOperation;
            }

          
            if (signbit(y[i]))
                hasNegativeInfinity = true;
            else
                hasPositiveInfinity = true;
            
            ++i;
            break;
        }

        if (isZero(x[i]) || isZero(y[i]))
        {
            ++i;
            continue;
        }

        sx = x[i].unpack(cx, ex);
        sy = y[i].unpack(cy, ey);
        cxx = cx; cyy = cy;
        flags |= coefficientMul(cx, ex, sx, cy, ey, sy, mode);
        flags |= coefficientAdd(cr, er, sr, cx, ex, sx, mode);
        ++i;
        if (flags & ExceptionFlags.overflow)
            break;
    }

    while (i < len)
    {
        if (isSignaling(x[i]) || isSignaling(y[i]))
        {
            result = D.nan;
            return ExceptionFlags.invalidOperation;
        }

        if (isNaN(x[i]) || isNaN(y[i]))
        {
            result = D.nan;
            return ExceptionFlags.none;
        }

        if (isInfinity(x[i]))
        {
            if (isZero(y[i]))
            {
                result = D.nan;
                return ExceptionFlags.invalidOperation;
            }

            if (isInfinity(y[i]))
            {
                if (signbit(x[i]) ^ signbit(y[i]))
                    hasNegativeInfinity = true;
                else
                    hasPositiveInfinity = true;

            }
            else
            {
                if (signbit(x[i]))
                    hasNegativeInfinity = true;
                else
                    hasPositiveInfinity = true;
            }
        }

        if (isInfinity(y[i]))
        {
            if (isZero(x[i]))
            {
                result = D.nan;
                return ExceptionFlags.invalidOperation;
            }


            if (signbit(y[i]))
                hasNegativeInfinity = true;
            else
                hasPositiveInfinity = true;
        }

        ++i;
    }

    if (hasPositiveInfinity)
    {
        if (hasNegativeInfinity)
        {
            result = D.nan;
            return ExceptionFlags.invalidOperation;
        }
        result = D.infinity;
        return ExceptionFlags.none;
    }

    if (hasNegativeInfinity)
    {
        result = -D.infinity;
        return ExceptionFlags.none;
    }

    flags |= coefficientAdjust(cr, er, cvt!T(DataType!D.max), sr, mode);
    return result.adjustedPack(cvt!(DataType!D)(cr), er, sr, precision, mode, flags);
}

ExceptionFlags decimalProd(D)(const(D)[] x, out D result, out int scale, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    ExceptionFlags flags;
    alias T = MakeUnsigned!(D.sizeof * 16);
    DataType!D cx;
    T cxx, cr;
    int ex, er;
    bool sx, sr;

    result = 0;
    scale = 0;
    bool hasInfinity;
    bool hasZero;
    bool infinitySign;
    bool zeroSign;
    size_t i = 0;
    while (i < x.length)
    {
        if (isSignaling(x[i]))
        {
            result = D.nan;
            return ExceptionFlags.invalidOperation;
        }

        if (isNaN(x[i]))
        {
            result = D.nan;
            return ExceptionFlags.none;
        }

        if (isInfinity(x[i]))
        {
            hasInfinity = true;
            infinitySign = cast(bool)(signbit(x[i]));
            ++i;
            break;
        }

        if (isZero(x[i]))
        {
            hasZero = true;
            zeroSign = cast(bool)(signbit(x[i]));
            ++i;
            break;
        }

        sx = x.unpack(cx, ex);
        cxx = cx;
        flags |= coefficientMul(cr, er, sr, cxx, ex, sx, mode);
        er -= cappedAdd(scale, er);
        ++i;

        if (flags & ExceptionFlags.overflow)
            break;
    }

    while (i < x.length)
    {
        //infinity or overflow detected
        if (isSignaling(x[i]))
        {
            result = D.nan;
            return ExceptionFlags.invalidOperation;
        }

        if (isNaN(x[i]))
        {
            result = D.nan;
            return ExceptionFlags.none;
        }

        if (isInfinity(x[i]))
        {
            hasInfinity = true;
            infinitySign ^= cast(bool)(signbit(x[i]));
        }
        else if (isZero(x[i]))
        {
            hasZero = true;
            zeroSign ^= cast(bool)(signbit(x[i]));
        }
        else
        {
            zeroSign ^= cast(bool)(signbit(x[i]));
        }


        ++i;
    }

    if (hasInfinity & hasZero)
    {
        result = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (hasInfinity)
    {
        result = infinitySign ? -D.infinity : D.infinity;
        return ExceptionFlags.none;
    }

    if (hasZero)
    {
        result = zeroSign ? -D.zero : D.zero;
        return ExceptionFlags.none;
    }

    flags |= coefficientAdjust(cr, er, cvt!T(DataType!D.max), sr, mode);
    return result.adjustedPack(cvt!(DataType!D)(cr), er, sr, precision, mode, flags);
}

ExceptionFlags decimalProdSum(D)(const(D)[] x, const(D)[] y, out D result, out int scale, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    size_t len = x.length;
    if (len > y.length)
        len = y.length;

    bool hasInfinity;
    bool hasZero;

    bool infinitySign;

    bool invalidSum;

    alias T = MakeUnsigned!(D.sizeof * 16);
    DataType!D cx, cy;
    T cxx, cyy, cr;
    int ex, ey, er;
    bool sx, sy, sr;

    size_t i = 0;
    while (i < len)
    {
        if (isSignaling(x[i]) || isSignaling(y[i]))
        {
            result = D.nan;
            return ExceptionFlags.invalidOperation;
        }

        if (isNaN(x[i]) || isNaN(y[i]))
        {
            result = D.nan;
            return ExceptionFlags.none;
        }

        if (isInfinity(x[i]))
        {
            if (isInfinity(y[i]) && signbit(x) != signbit(y))
            {
                invalidSum = true;
                ++i;
                break;
            }

            hasInfinity = true;
            infinitySign = cast(bool)signbit(x[i]);
            ++i;
            break;
        }

        if (isInfinity(y[i]))
        {
            hasInfinity = true;
            infinitySign = cast(bool)signbit(x[i]);
            ++i;
            break;
        }

        if (x[i] == -y[i])
        {
            hasZero = true;
            ++i;
            break;
        }
        sx = x[i].unpack(cx, ex);
        sy = y[i].unpack(cy, ey);
        cxx = cx; cyy = cy;
        flags |= coefficientAdd(cx, ex, sx, cy, ey, sy, mode);
        flags |= coefficientMul(cr, er, sr, cx, ex, sx, mode);
        er -= cappedAdd(scale, er);
        ++i;
        if (flags & ExceptionFlags.overflow)
            break;
        if (flags & ExceptionFlags.underflow)
            break;
        
    }

    while (i < len)
    {
        //inf, zero or overflow, underflow, invalidSum;
        if (isSignaling(x[i]) || isSignaling(y[i]))
        {
            result = D.nan;
            return ExceptionFlags.invalidOperation;
        }

        if (isNaN(x[i]) || isNaN(y[i]))
        {
            result = D.nan;
            return ExceptionFlags.none;
        }

        if (isInfinity(x[i]))
        {
            if (isInfinity(y[i]) && signbit(x) != signbit(y))
                invalidSum = true;
            else
            {
                hasInfinity = true;
                infinitySign ^= cast(bool)signbit(x[i]);
            }
        }
        else if (isInfinity(y[i]))
        {
            hasInfinity = true;
            infinitySign ^= cast(bool)signbit(y[i]);
        }
        else if (x[i] == -y[i])
            hasZero = true;
        ++i;
    }

    if (invalidSum)
    {
        result = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (hasInfinity & hasZero)
    {
        result = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (hasInfinity)
    {
        result = infinitySign ? -D.infinity : D.infinity;
        return ExceptionFlags.none;
    }

    if (hasZero)
    {
        result = D.zero;
        return ExceptionFlags.none;
    }

    flags |= coefficientAdjust(cr, er, cvt!T(DataType!D.max), sr, mode);
    return result.adjustedPack(cvt!(DataType!D)(cr), er, sr, precision, mode, flags);
}

ExceptionFlags decimalProdDiff(D)(const(D)[] x, const(D)[] y, out D result, out int scale, const int precision, const RoundingMode mode)
if (isDecimal!D)
{
    size_t len = x.length;
    if (len > y.length)
        len = y.length;

    bool hasInfinity;
    bool hasZero;

    bool infinitySign;

    bool invalidSum;

    alias T = MakeUnsigned!(D.sizeof * 16);
    DataType!D cx, cy;
    T cxx, cyy, cr;
    int ex, ey, er;
    bool sx, sy, sr;

    size_t i = 0;
    while (i < len)
    {
        if (isSignaling(x[i]) || isSignaling(y[i]))
        {
            result = D.nan;
            return ExceptionFlags.invalidOperation;
        }

        if (isNaN(x[i]) || isNaN(y[i]))
        {
            result = D.nan;
            return ExceptionFlags.none;
        }

        if (isInfinity(x[i]))
        {
            if (isInfinity(y[i]) && signbit(x) != signbit(y))
            {
                invalidSum = true;
                ++i;
                break;
            }

            hasInfinity = true;
            infinitySign = cast(bool)signbit(x[i]);
            ++i;
            break;
        }

        if (isInfinity(y[i]))
        {
            hasInfinity = true;
            infinitySign = cast(bool)signbit(x[i]);
            ++i;
            break;
        }

        if (x[i] == y[i])
        {
            hasZero = true;
            ++i;
            break;
        }
        sx = x[i].unpack(cx, ex);
        sy = y[i].unpack(cy, ey);
        cxx = cx; cyy = cy;
        flags |= coefficientSub(cx, ex, sx, cy, ey, sy, mode);
        flags |= coefficientMul(cr, er, sr, cx, ex, sx, mode);
        er -= cappedAdd(scale, er);
        ++i;
        if (flags & ExceptionFlags.overflow)
            break;
        if (flags & ExceptionFlags.underflow)
            break;

    }

    while (i < len)
    {
        //inf, zero or overflow, underflow, invalidSum;
        if (isSignaling(x[i]) || isSignaling(y[i]))
        {
            result = D.nan;
            return ExceptionFlags.invalidOperation;
        }

        if (isNaN(x[i]) || isNaN(y[i]))
        {
            result = D.nan;
            return ExceptionFlags.none;
        }

        if (isInfinity(x[i]))
        {
            if (isInfinity(y[i]) && signbit(x) != signbit(y))
                invalidSum = true;
            else
            {
                hasInfinity = true;
                infinitySign ^= cast(bool)signbit(x[i]);
            }
        }
        else if (isInfinity(y[i]))
        {
            hasInfinity = true;
            infinitySign ^= cast(bool)signbit(y[i]);
        }
        else if (x[i] == y[i])
            hasZero = true;
        ++i;
    }

    if (invalidSum)
    {
        result = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (hasInfinity & hasZero)
    {
        result = D.nan;
        return ExceptionFlags.invalidOperation;
    }

    if (hasInfinity)
    {
        result = infinitySign ? -D.infinity : D.infinity;
        return ExceptionFlags.none;
    }

    if (hasZero)
    {
        result = D.zero;
        return ExceptionFlags.none;
    }

    flags |= coefficientAdjust(cr, er, cvt!T(DataType!D.max), sr, mode);
    return result.adjustedPack(cvt!(DataType!D)(cr), er, sr, precision, mode, flags);
}

ExceptionFlags decimalPoly(D1, D2, D)(auto const ref D1 x, const(D2)[] a, out D result)
if (isDecimal!(D1, D2) && is(D: CommonDecimal!(D1, D2)))
{
    if (!a.length)
    {
        result = 0;
        return ExceptionFlags.none;
    }
    ptrdiff_t i = a.length - 1;
    D result = a[i];
    ExceptionFlags flags;
    while (--i >= 0)
    {
        flags |= decimalMul(result, x);
        flags |= decimalAdd(result, a[i]);
    }
    return flags;    
}

/* ****************************************************************************************************************** */
/* COEFFICCIENT ARITHMETIC                                                                                            */       
/* ****************************************************************************************************************** */
//divPow10          - inexact
//mulPow10          - overflow
//coefficientAdjust - inexact, overflow, underflow
//coefficientExpand - none
//coefficientShrink - inexact
//coefficientAdd    - inexact, overflow
//coefficientMul    - inexact, overflow, underflow
//coefficientDiv    - inexact, overflow, underflow, div0
//coefficientMod    - inexact, overflow, underflow, invalid
//coefficientFMA    - inexact, overflow, underflow
//coefficientCmp    - none
//coefficientEqu    - none
//coefficientSqr    - inexact, overflow, underflow


pure @safe nothrow @nogc
int cappedSub(ref int target, const int value)
{
    bool ovf;
    int result = subs(target, value, ovf);
    if (ovf)
    {
        if (value > 0)
        {
            //target was negative
            result = target - int.min;
            target = int.min;
        }
        else
        {
            //target was positive
            result = target - int.max;
            target = int.max;
        }
        return result;
    }
    else
    {
        target -= value;
        return value;
    }
}

pure @safe nothrow @nogc
int cappedAdd(ref int target, const int value)
{
    bool ovf;
    int result = adds(target, value, ovf);
    if (ovf)
    {
        if (value > 0)
        {
            //target was positive
            result = int.max - target;
            target = int.max;      
        }
        else
        {
            //target was negative
            result = int.min - target;
            target = int.min;
        }
        return result;
    }
    else
    {
        target += value;
        return value;
    }
}

unittest
{
    int ex = int.min + 1;
    int px = cappedSub(ex, 3);
    assert (ex == int.min);
    assert (px == 1);

    ex = int.min + 3;
    px = cappedSub(ex, 2);
    assert (ex == int.min + 1);
    assert (px == 2);

    ex = int.max - 1;
    px = cappedSub(ex, -2);
    assert (ex == int.max);
    assert (px == -1);

    ex = int.max - 3;
    px = cappedSub(ex, -2);
    assert (ex == int.max - 1);
    assert(px == -2);


}


//divides coefficient by 10^power
//inexact
ExceptionFlags divpow10(T)(ref T coefficient, const int power, const bool isNegative, const RoundingMode mode)
if (isAnyUnsigned!T)
in
{
    assert (power >= 0);
}
body
{
    Unqual!T remainder;

    if (coefficient == 0U)
        return ExceptionFlags.none;

    if (power == 0)
        return ExceptionFlags.none;

    if (power >= pow10!T.length)
    {
        remainder = coefficient;
        coefficient = 0U;
    }
    else
        remainder = divrem(coefficient, pow10!T[power]);

    if (remainder == 0U)
        return ExceptionFlags.none;

    immutable half = power >= pow10!T.length ? T.max : pow10!T[power] >>> 1;
    final switch (mode)
    {
        case RoundingMode.tiesToEven:
            if (remainder > half)
                ++coefficient;
            else if ((remainder == half) && ((coefficient & 1U) != 0U))
                ++coefficient;
            break;
        case RoundingMode.tiesToAway:
            if (remainder >= half)
                ++coefficient;
            break;
        case RoundingMode.towardNegative:
            if (isNegative)
                ++coefficient;
            break;
        case RoundingMode.towardPositive:
            if (!isNegative)
                ++coefficient;
            break;
        case RoundingMode.towardZero:
            break;
    }
    return ExceptionFlags.inexact;
}

unittest
{
    struct S {uint c; int p; bool n; RoundingMode r; uint outc; bool inexact; }

    S[] test = 
    [
        S (0, 0, false, RoundingMode.tiesToAway, 0, false),
        S (0, 0, false, RoundingMode.tiesToEven, 0, false),
        S (0, 0, false, RoundingMode.towardNegative, 0, false),
        S (0, 0, false, RoundingMode.towardPositive, 0, false),
        S (0, 0, false, RoundingMode.towardZero, 0, false),

        S (10, 1, false, RoundingMode.tiesToAway, 1, false),
        S (10, 1, false, RoundingMode.tiesToEven, 1, false),
        S (10, 1, false, RoundingMode.towardNegative, 1, false),
        S (10, 1, false, RoundingMode.towardPositive, 1, false),
        S (10, 1, false, RoundingMode.towardZero, 1, false),

        S (13, 1, false, RoundingMode.tiesToAway, 1, true),
        S (13, 1, false, RoundingMode.tiesToEven, 1, true),
        S (13, 1, false, RoundingMode.towardNegative, 1, true),
        S (13, 1, false, RoundingMode.towardPositive, 2, true),
        S (13, 1, false, RoundingMode.towardZero, 1, true),

        S (13, 1, true, RoundingMode.tiesToAway, 1, true),
        S (13, 1, true, RoundingMode.tiesToEven, 1, true),
        S (13, 1, true, RoundingMode.towardNegative, 2, true),
        S (13, 1, true, RoundingMode.towardPositive, 1, true),
        S (13, 1, true, RoundingMode.towardZero, 1, true),


        S (15, 1, false, RoundingMode.tiesToAway, 2, true),
        S (15, 1, false, RoundingMode.tiesToEven, 2, true),
        S (15, 1, false, RoundingMode.towardNegative, 1, true),
        S (15, 1, false, RoundingMode.towardPositive, 2, true),
        S (15, 1, false, RoundingMode.towardZero, 1, true),

        S (15, 1, true, RoundingMode.tiesToAway, 2, true),
        S (15, 1, true, RoundingMode.tiesToEven, 2, true),
        S (15, 1, true, RoundingMode.towardNegative, 2, true),
        S (15, 1, true, RoundingMode.towardPositive, 1, true),
        S (15, 1, true, RoundingMode.towardZero, 1, true),


        S (18, 1, false, RoundingMode.tiesToAway, 2, true),
        S (18, 1, false, RoundingMode.tiesToEven, 2, true),
        S (18, 1, false, RoundingMode.towardNegative, 1, true),
        S (18, 1, false, RoundingMode.towardPositive, 2, true),
        S (18, 1, false, RoundingMode.towardZero, 1, true),

        S (18, 1, true, RoundingMode.tiesToAway, 2, true),
        S (18, 1, true, RoundingMode.tiesToEven, 2, true),
        S (18, 1, true, RoundingMode.towardNegative, 2, true),
        S (18, 1, true, RoundingMode.towardPositive, 1, true),
        S (18, 1, true, RoundingMode.towardZero, 1, true),

        S (25, 1, false, RoundingMode.tiesToAway, 3, true),
        S (25, 1, false, RoundingMode.tiesToEven, 2, true),
        S (25, 1, false, RoundingMode.towardNegative, 2, true),
        S (25, 1, false, RoundingMode.towardPositive, 3, true),
        S (25, 1, false, RoundingMode.towardZero, 2, true),

        S (25, 1, true, RoundingMode.tiesToAway, 3, true),
        S (25, 1, true, RoundingMode.tiesToEven, 2, true),
        S (25, 1, true, RoundingMode.towardNegative, 3, true),
        S (25, 1, true, RoundingMode.towardPositive, 2, true),
        S (25, 1, true, RoundingMode.towardZero, 2, true),
    ];

    foreach (ref s; test)
    {
        auto flags = divpow10(s.c, s.p, s.n, s.r);
        assert (s.c == s.outc);
        assert (flags == ExceptionFlags.inexact ? s.inexact : !s.inexact);

    }

}

//multiplies coefficient by 10^^power, returns possible overflow
//overflow
ExceptionFlags mulpow10(T)(ref T coefficient, const int power)
if (isAnyUnsigned!T)
in 
{
    assert (power >= 0);
}
body
{
    if (coefficient == 0U || power == 0)
        return ExceptionFlags.none;   
    if (power >= pow10!T.length || coefficient > maxmul10!T[power])
        return ExceptionFlags.overflow;
    coefficient *= pow10!T[power];
    return ExceptionFlags.none;   
}


//adjusts coefficient to fit minExponent <= exponent <= maxExponent and coefficient <= maxCoefficient
//inexact, overflow, underflow
ExceptionFlags coefficientAdjust(T)(ref T coefficient, ref int exponent, const int minExponent, const int maxExponent, 
                                    const T maxCoefficient, const bool isNegative, const RoundingMode mode)
if (isAnyUnsigned!T)
in
{
    assert (minExponent <= maxExponent);
    assert (maxCoefficient >= 1U);
}
body
{
    bool overflow;
    ExceptionFlags flags;

    if (coefficient == 0U)
    {
        exponent = 0;
        if (exponent < minExponent)
            exponent = minExponent;      
        if (exponent > maxExponent)
            exponent = maxExponent;
        return ExceptionFlags.none;
    }

    if (exponent < minExponent)
    {
        //increase exponent, divide coefficient 
        immutable dif = minExponent - exponent;
        flags = divpow10(coefficient, dif, isNegative, mode);
        exponent += dif;
    }
    else if (exponent > maxExponent)
    {
        //decrease exponent, multiply coefficient
        immutable dif = exponent - maxExponent;
        flags = mulpow10(coefficient, dif);
        if (flags & ExceptionFlags.overflow)
            return flags;
        else
            exponent -= dif;
    }

    if (coefficient > maxCoefficient)
    {
        //increase exponent, divide coefficient
        auto dif = prec(coefficient) - prec(maxCoefficient);
        if (!dif) 
            dif = 1;
        flags |= divpow10(coefficient, dif, isNegative, mode);
        if (coefficient > maxCoefficient)
        {
            //same precision but greater
            flags |= divpow10(coefficient, 1, isNegative, mode);         
            ++dif;
        }
        if (cappedAdd(exponent, dif) != dif)
        {
            if (coefficient != 0U)
                return flags | ExceptionFlags.overflow;
        }
    }


    //coefficient became 0, dont' bother with exponents;
    if (coefficient == 0U)
    {
        exponent = 0;
        if (exponent < minExponent)
            exponent = minExponent;      
        if (exponent > maxExponent)
            exponent = maxExponent;
        return flags;
    }

    if (exponent < minExponent)
        return flags | ExceptionFlags.underflow;
    
    if (exponent > maxExponent)
        return flags | ExceptionFlags.overflow;


    return flags;

}


//adjusts coefficient to fit minExponent <= exponent <= maxExponent
//inexact, overflow, underflow
ExceptionFlags coefficientAdjust(T)(ref T coefficient, ref int exponent, const int minExponent, const int maxExponent, 
                                    const bool isNegative, const RoundingMode mode)
if (isAnyUnsigned!T)
in
{
    assert (minExponent <= maxExponent);
}
body
{
    return coefficientAdjust(coefficient, exponent, minExponent, maxExponent, T.max, isNegative, mode);
}

//adjusts coefficient to fit coefficient in maxCoefficient
//inexact, overflow, underflow
ExceptionFlags coefficientAdjust(T)(ref T coefficient, ref int exponent, const T maxCoefficient, 
                                    const bool isNegative, const RoundingMode mode)
if (isAnyUnsigned!T)
in
{
    assert (maxCoefficient >= 1U);
}
body
{
    return coefficientAdjust(coefficient, exponent, int.min, int.max, maxCoefficient, isNegative, mode);
}


//adjusts coefficient to fit minExponent <= exponent <= maxExponent and to fit precision
//inexact, overflow, underflow
ExceptionFlags coefficientAdjust(T)(ref T coefficient, ref int exponent, const int minExponent, const int maxExponent, 
                                  const int precision, const bool isNegative, const RoundingMode mode)
if (isAnyUnsigned!T)
in
{
    assert (precision >= 1);
    assert (minExponent <= maxExponent);
}
body
{
    immutable maxCoefficient = precision >= pow10!T.length ? T.max : pow10!T[precision] - 1U;
    auto flags = coefficientAdjust(coefficient, exponent, minExponent, maxExponent, maxCoefficient, isNegative, mode);
    if (flags & (ExceptionFlags.overflow | ExceptionFlags.underflow))
        return flags;

    immutable p = prec(coefficient);
    if (p > precision)
    {
        flags |= divpow10(coefficient, 1, isNegative, mode);
        if (coefficient == 0U)
        {
            exponent = 0;
            if (exponent < minExponent)
                exponent = minExponent;      
            if (exponent > maxExponent)
                exponent = maxExponent;
            return flags;
        }
        else
        {
            if (cappedAdd(exponent, 1) != 1)
                return flags | ExceptionFlags.overflow;
            if (exponent > maxExponent)
                return flags | ExceptionFlags.overflow;
        }
    }
    return flags;
}

//adjusts coefficient to fit precision
//inexact, overflow, underflow
@safe pure nothrow @nogc
ExceptionFlags coefficientAdjust(T)(ref T coefficient, ref int exponent, 
                                    const int precision, const bool isNegative, const RoundingMode mode)
if (isAnyUnsigned!T)
in
{
    assert (precision >= 1);
}
body
{
    return coefficientAdjust(coefficient, exponent, int.min, int.max, precision, isNegative, mode);
}

//shrinks coefficient by cutting out terminating zeros and increasing exponent
@safe pure nothrow @nogc
void coefficientShrink(T)(ref T coefficient, ref int exponent)
{
    if (coefficient > 9U && (coefficient & 1U) == 0U && exponent < int.max)
    {
        Unqual!T c = coefficient;
        Unqual!T r = divrem(c, 10U);
        int e = exponent + 1;
        while (r == 0U)
        {
            coefficient = c;
            exponent = e;
            if ((c & 1U) || e == int.max)
                break;
            r = divrem(c, 10U);
            ++e;
        }
    }
}

//expands cx with 10^^target if possible
@safe pure nothrow @nogc
void coefficientExpand(T)(ref T cx, ref int ex, ref int target)
in
{
    assert (cx);
    assert (target > 0);
}
body
{
    int px = prec(cx);
    int maxPow10 = cast(int)pow10!T.length - px;
    auto maxCoefficient = maxmul10!T[$ - px];
    if (cx > maxCoefficient)
        --maxPow10;
    auto pow = target > maxPow10 ? maxPow10 : target;    
    pow = cappedSub(ex, pow);
    if (pow)
    {
        cx *= pow10!T[pow];
        target -= pow;
    }
}

unittest
{
    struct S {uint x1; int ex1; int target1; uint x2; int ex2; int target2; }
    S[] tests =
    [
        S(1, 0, 4, 10000, -4, 0),
        S(429496729, 0, 1, 4294967290, -1, 0),
        S(429496739, 0, 1, 429496739, 0, 1),
        S(429496729, 0, 2, 4294967290, -1, 1),
        S(42949672, 0, 1, 429496720, -1, 0),
        S(42949672, 0, 2, 4294967200, -2, 0),
        S(42949672, 0, 3, 4294967200, -2, 1),
    ];

    foreach( s; tests)
    {
        coefficientExpand(s.x1, s.ex1, s.target1);
        assert (s.x1 == s.x2);
        assert (s.ex1 == s.ex2);
        assert (s.target1 == s.target2);
    }
}

//shrinks cx with 10^^target
//inexact
@safe pure nothrow @nogc
ExceptionFlags coefficientShrink(T)(ref T cx, ref int ex, const bool sx, ref int target, const RoundingMode mode)
in
{
    assert (cx);
    assert (target > 0);
}
body
{
    auto pow = cappedAdd(ex, target);
    if (pow)
    {
        auto flags = divpow10(cx, pow, sx, mode);
        target -= pow;
        return flags;
    }
    else
        return ExceptionFlags.none;
}

//inexact
@safe pure nothrow @nogc
ExceptionFlags exponentAlign(T)(ref T cx, ref int ex, const bool sx, ref T cy, ref int ey, const bool sy, const RoundingMode mode)
out
{
    assert (ex == ey);
}
body
{
    if (ex == ey)
        return ExceptionFlags.none;

    if (!cx)
    {
        ex = ey;
        return ExceptionFlags.none;
    }
    
    if (!cy)
    {
        ey = ex;
        return ExceptionFlags.none;
    }

    ExceptionFlags flags;
    int dif = ex - ey;
    if (dif > 0) //ex > ey
    {
        coefficientExpand(cx, ex, dif);
        if (dif)
            flags = coefficientShrink(cy, ey, sy, dif, mode);
        assert(!dif);
    }
    else //ex < ey
    {
        dif = -dif;
        coefficientExpand(cy, ey, dif);
        if (dif)
            flags = coefficientShrink(cx, ex, sx, dif, mode);
        assert(!dif);
    }
    return flags;
}

//inexact, overflow
@safe pure nothrow @nogc
ExceptionFlags coefficientAdd(T)(ref T cx, ref int ex, ref bool sx, const T cy, const int ey, const bool sy, const RoundingMode mode)
{
    if (!cy)
        return ExceptionFlags.none;
    
    if (!cx)
    {
        cx = cy;
        ex = ey;
        sx = sy;
        return ExceptionFlags.none;
    }

    Unqual!T cyy = cy;
    int eyy = ey;

    auto flags = exponentAlign(cx, ex, sx, cyy, eyy, sy, mode);

    if (!cyy)
        return flags;
    
    if (!cx)
    {
        cx = cyy;
        sx = sy;
        return flags;
    }

    if (sx == sy)
    {
        Unqual!T savecx = cx;
        auto carry = xadd(cx, cyy);
        if (carry)
        {
            if (!cappedAdd(ex, 1))
                return flags | ExceptionFlags.overflow;
            flags |= divpow10(savecx, 1, sx, mode);
            flags |= divpow10(cyy, 1, sy, mode);
            cx = savecx + cyy;
        }
        return flags;
    }
    else
    {
        if (cx == cyy)
        {
            cx = T(0U);
            ex = 0;
            sx = false;
            return flags;
        }

        if (cx > cyy)
            cx -= cyy;
        else
        {
            cx = cyy - cx;
            sx = sy;
        }
        return flags;
    }
}

//inexact, overflow, underflow
@safe pure nothrow @nogc
ExceptionFlags coefficientMul(T)(ref T cx, ref int ex, ref bool sx, const T cy, const int ey, const bool sy, const RoundingMode mode)
{
    if (!cy)
    {
        cx = T(0U);
        sx ^= sy;
        return ExceptionFlags.none;
    }

    if (!cx)
    {
        cx = cy;
        ex = ey;
        sx ^= sy;
        return ExceptionFlags.none;
    }

    auto r = xmul(cx, cy);
    
    if (cappedAdd(ex, ey) != ey)
        return ex < 0 ? ExceptionFlags.underflow : ExceptionFlags.overflow;

    sx ^= sy;

    if (r > T.max)
    {
        auto px = prec(r);
        auto pm = prec(T.max) - 1;
        auto flags = divpow10(r, px - pm, sx, mode);
        if (cappedAdd(ex, px - pm) != px - pm)
            return ex < 0 ? ExceptionFlags.underflow : ExceptionFlags.overflow;
        cx = cvt!T(r);
        return flags;
    }
    else
    {
        cx = cvt!T(r);
        return ExceptionFlags.none;
    }
}

//div0, overflow, underflow
@safe pure nothrow @nogc
ExceptionFlags coefficientDiv(T)(ref T cx, ref int ex, ref bool sx, const T cy, const int ey, const bool sy, const RoundingMode mode)
{
    if (!cy)
    {
        sx ^= sy;
        return ExceptionFlags.divisionByZero;
    }

    if (!cx)
    {
        ex = 0;
        sx ^= sy;
        return ExceptionFlags.none;
    }

    if (cy == 1U)
    {
        if (cappedSub(ex, ey) != ey)
            return ex < 0 ? ExceptionFlags.underflow : ExceptionFlags.overflow;
        sx ^= sy;
        return ExceptionFlags.none;
    }

    Unqual!T savecx = cx;
    sx ^= sy;
    auto r = divrem(cx, cy);
    if (!r)
    {
        if (cappedSub(ex, ey) != ey)
           return ex < 0 ? ExceptionFlags.underflow : ExceptionFlags.overflow; 
        return ExceptionFlags.none;
    }

    alias U = MakeUnsigned!(T.sizeof * 16);
    U cxx = savecx;
    auto px = prec(savecx);
    auto pm = prec(U.max) - 1;
    mulpow10(cxx, pm - px);
    auto scale = pm - px - cappedSub(ex, pm - px);
    auto s = divrem(cxx, cy);
    ExceptionFlags flags;
    if (s)
    {
        immutable half = cy >>> 1;
        final switch (mode)
        {
            case RoundingMode.tiesToEven:
                if (s > half)
                    ++cxx;
                else if ((s == half) && ((cxx & 1U) == 0U))
                    ++cxx;
                break;
            case RoundingMode.tiesToAway:
                if (s >= half)
                    ++cxx;
                break;
            case RoundingMode.towardNegative:
                if (sx)
                    ++cxx;
                break;
            case RoundingMode.towardPositive:
                if (!sx)
                    ++cxx;
                break;
            case RoundingMode.towardZero:
                break;
        }
        flags = ExceptionFlags.inexact;
    }

    flags |= coefficientAdjust(cxx, ex, U(T.max), sx, mode);

    if (flags & ExceptionFlags.underflow)
    {
        cx = 0U;
        ex = 0U;
        return flags;
    }

    if (flags & ExceptionFlags.overflow)
        return flags;

    
    cx = cast(T)cxx;
    if (cappedSub(ex, ey) != ey)
        flags |= ex < 0 ? ExceptionFlags.underflow : ExceptionFlags.overflow; 
    if (cappedSub(ex, scale) != scale)
        flags |= ex < 0 ? ExceptionFlags.underflow : ExceptionFlags.overflow; 

    return flags;
}

//inexact, overflow, underflow
@safe pure nothrow @nogc
ExceptionFlags coefficientFMA(T)(ref T cx, ref int ex, ref bool sx, const T cy, const int ey, const bool sy, const T cz, const int ez, const bool sz, const RoundingMode mode)
{
    if (!cx || !cy)
    {
        cx = cz;
        ex = ez;
        sx = sz;
        return ExceptionFlags.none;
    }

    if (!cz)
        return coefficientMul(cx, ex, sx, cy, ey, sy, mode);

    
    if (cappedAdd(ex, ey) != ey)
        return ex < 0 ? ExceptionFlags.underflow : ExceptionFlags.overflow;
    auto m = xmul(cx, cy);
    sx ^= sy;

    typeof(m) czz = cz;
    auto flags = coefficientAdd(m, ex, sx, czz, ez, sz, mode);
    auto pm = prec(m);
    auto pmax = prec(T.max) - 1;
    if (pm > pmax)
    {
        flags |= divpow10(m, pm - pmax, sx, mode);
        if (cappedAdd(ex, pm - pmax) != pm - pmax)
            return ex < 0 ? ExceptionFlags.underflow : ExceptionFlags.overflow;
    }
    cx = cast(Unqual!T)m;
    return flags;
}

//inexact
@safe pure nothrow @nogc
ExceptionFlags coefficientRound(T)(ref T cx, ref int ex, const bool sx, const RoundingMode mode)
{
    if (ex < 0)
    {
        auto flags = divpow10(cx, -ex, sx, mode);
        ex = 0;
        return flags;
    }
    return ExceptionFlags.none;
}

//inexact, overflow, underflow
@safe pure nothrow @nogc
ExceptionFlags coefficientMod(T)(ref T cx, ref int ex, ref bool sx, const T cy, const int ey, const bool sy, const RoundingMode mode)
{
    if (!cx)
        return ExceptionFlags.invalidOperation;
    Unqual!T rcx = cx;
    int rex = ex;
    bool rsx = sx;
    auto flags = coefficientDiv(rcx, rex, rsx, cy, ey, sy, mode);   
    if (flags & ExceptionFlags.underflow)
        return flags &= ~ExceptionFlags.underflow;
    if (flags & (ExceptionFlags.divisionByZero | ExceptionFlags.overflow))
        return flags;
    flags |= coefficientRound(rcx, rex, rsx, mode);
    flags |= coefficientMul(rcx, rex, rsx, cy, ey, sy, mode);
    if (flags & ExceptionFlags.underflow)
        return flags &= ~ExceptionFlags.underflow;
    if (flags & ExceptionFlags.overflow)
        return flags;
    flags |= coefficientAdd(cx, ex, sx, rcx, rex, !rsx, mode);
    return flags;
}

@safe pure nothrow @nogc
int coefficientCmp(T)(const T cx, const int ex, const bool sx, const T cy, const int ey, const bool sy)
{
    if (!cx)
        return cy ? (sy ? 1 : -1) : 0;
    if (!cy)
        return sx ? -1 : 1;
    
    if (sx && !sy)
        return -1;
    else if (!sx && sy)
        return 1;
    else
        return sx ? -coefficientCmp(cx, ex, cy, ey) : coefficientCmp(cx, ex, cy, ey);
}

@safe pure nothrow @nogc
int coefficientCmp(T)(const T cx, const int ex, const T cy, const int ey)
{
    if (!cx)
        return cy ? -1 : 0;
    if (!cy)
        return 1;

    int px = prec(cx);
    int py = prec(cy);

    if (px > py)
    {
        int eyy = ey - (px - py);
        if (ex > eyy)
            return 1;
        if (ex < eyy)
            return -1;
        Unqual!T cyy = cy;
        mulpow10(cyy, px - py);
        if (cx > cyy)
            return 1;
        if (cx < cyy)
            return -1;
        return 0;
    }

    if (px < py)
    {
        int exx = ex - (py - px);
        if (exx > ey)
            return 1;
        if (exx < ey)
            return -1;
        Unqual!T cxx = cx;
        mulpow10(cxx, py - px);       
        if (cxx > cy)
            return 1;
        if (cxx < cy)
            return -1;
        return 0;
    }

    if (ex > ey)
        return 1;
    if (ex < ey)
        return -1;

    if (cx > cy)
        return 1;
    else if (cx < cy)
        return -1;
    return 0;
    
}

@safe pure nothrow @nogc
bool coefficientEqu(T)(const T cx, const int ex, const bool sx, const T cy, const int ey, const bool sy)
{
    if (!cx)
        return cy == 0U;

    if (sx != sy)
        return false;
    else
    {
        int px = prec(cx);
        int py = prec(cy);

        if (px > py)
        {     
            int eyy = ey - (px - py);
            if (ex != eyy)
                return false;
            Unqual!T cyy = cy;
            mulpow10(cyy, px - py);
            return cx == cyy;
        }

        if (px < py)
        {
            int exx = ex - (py - px);
            if (exx != ey)
                return false;
            Unqual!T cxx = cx;
            mulpow10(cxx, py - px);       
            return cxx == cy;
        }

        return cx == cy;
    }
}

@safe pure nothrow @nogc
bool coefficientApproxEqu(T)(const T cx, const int ex, const bool sx, const T cy, const int ey, const bool sy)
{
    //same as coefficientEqu, but we ignore the last digit if coefficient > 10^max
    //this is useful in convergence loops to not become infinite
    if (!cx)
        return cy == 0U;

    if (sx != sy)
        return false;
    else
    {
        int px = prec(cx);
        int py = prec(cy);

        if (px > py)
        {     
            int eyy = ey - (px - py);
            if (ex != eyy)
                return false;
            Unqual!T cyy = cy;
            mulpow10(cyy, px - py);
            if (cx > pow10!T[$ - 2])
                return cx >= cy ? cx - cy < 10U : cy - cx < 10U;
            return cx == cy;
        }

        if (px < py)
        {
            int exx = ex - (py - px);
            if (exx != ey)
                return false;
            Unqual!T cxx = cx;
            mulpow10(cxx, py - px);  
            if (cxx > pow10!T[$ - 2])
                return cxx >= cy ? cxx - cy < 10U : cy - cxx < 10U;
            return cx == cy;
        }

        if (cx > pow10!T[$ - 2])
            return cx >= cy ? cx - cy < 10U : cy - cx < 10U;

        return cx == cy;
    }
}

//inexact, overflow, underflow
@safe pure nothrow @nogc
ExceptionFlags coefficientSqr(T)(ref T cx, ref int ex, const RoundingMode mode)
{
    if (!cx)
    {
        cx = T(0U);
        ex = 0;
        return ExceptionFlags.none;
    }

    auto r = xsqr(cx);

    int ey = ex;
    if (cappedAdd(ex, ey) != ey)
        return ex < 0 ? ExceptionFlags.underflow : ExceptionFlags.overflow;


    if (r > T.max)
    {
        auto px = prec(r);
        auto pm = prec(T.max) - 1;
        auto flags = divpow10(r, px - pm, false, mode);
        if (cappedAdd(ex, px - pm) != px - pm)
            return ex < 0 ? ExceptionFlags.underflow : ExceptionFlags.overflow;
        cx = cvt!T(r);
        return flags;
    }
    else
    {
        cx = cvt!T(r);
        return ExceptionFlags.none;
    }
}

@safe pure nothrow @nogc
ExceptionFlags coefficientSqrt(T)(ref T cx, ref int ex)
{
    // Newton-Raphson: x = (x + n/x) / 2;

    if (!cx)
    {
        cx = 0U;
        ex = 0;
        return ExceptionFlags.none;
    }

    immutable Unqual!T cn = cx;
    immutable int en = ex;
    bool sx;

    enum two = T(2U);

    //shadow x
    Unqual!T cy;
    int ey;
    bool sy;

    coefficientDiv(cx, ex, sx, two, 0, false, RoundingMode.implicit);

    do
    {
        cy = cx;
        ey = ex;

        Unqual!T cf = cn;
        int ef = en;
        bool sf;

        coefficientDiv(cf, ef, sf, cx, ex, false, RoundingMode.implicit);
        coefficientAdd(cx, ex, sx, cf, ef, false, RoundingMode.implicit);
        coefficientDiv(cx, ex, sx, two, 0, false, RoundingMode.implicit);
    }
    while (!coefficientApproxEqu(cx, ex, false, cy, ey, false) && cx);

    if (!cx)
        return ExceptionFlags.underflow;

    coefficientMul(cy, ey, sy, cx, ex, false, RoundingMode.implicit);

    return coefficientEqu(cy, ey, false, cn, en, false) ?
        ExceptionFlags.none : ExceptionFlags.inexact;
}

@safe pure nothrow @nogc
ExceptionFlags coefficientCbrt(T)(ref T cx, ref int ex, ref bool sx)
{
    // Newton-Raphson: x = (2x + N/x2)/3

    if (!cx)
    {
        cx = 0U;
        ex = 0;
        return ExceptionFlags.none;
    }

    immutable Unqual!T cn = cx;
    immutable int en = ex;
    immutable bool sn = sx;

    enum two = T(2U);
    enum three = T(3U);

    //shadow x
    Unqual!T cy;
    int ey;
    bool sy;

    coefficientDiv(cx, ex, sx, three, 0, false, RoundingMode.implicit);

    do
    {
        cy = cx;
        ey = ex;
        
        Unqual!T cxx = cx;
        int exx = ex;
        bool sxx;
        coefficientSqr(cxx, exx, RoundingMode.implicit);

        Unqual!T cf = cn;
        int ef = en;
        bool sf;

        coefficientDiv(cf, ef, sf, cxx, exx, false, RoundingMode.implicit);
        coefficientMul(cx, ex, sx, two, 0, false, RoundingMode.implicit);
        coefficientAdd(cx, ex, sx, cf, ef, false, RoundingMode.implicit);
        coefficientDiv(cx, ex, sx, three, 0, false, RoundingMode.implicit);
        //writefln("%10d %10d %10d %10d", cx, ex, cy, ey);
    }
    while (!coefficientApproxEqu(cx, ex, false, cy, ey, false) && cx);

    if (!cx)
        return ExceptionFlags.underflow;

    sx = sn;

    coefficientMul(cy, ey, sy, cx, ex, false, RoundingMode.implicit);
    coefficientMul(cy, ey, sy, cx, ex, false, RoundingMode.implicit);


    return coefficientEqu(cy, ey, false, cn, en, false) ?
        ExceptionFlags.none : ExceptionFlags.inexact;

    
}

@safe pure nothrow @nogc
ExceptionFlags coefficientHypot(T)(ref T cx, ref int ex, auto const ref T cy, const int ey)
{
    Unqual!T cyy = cy;
    int eyy = ey;
    bool sx;
    auto flags = coefficientSqr(cx, ex, RoundingMode.implicit);
    flags |= coefficientSqr(cyy, eyy, RoundingMode.implicit);
    flags |= coefficientAdd(cx, ex, sx, cyy, eyy, false, RoundingMode.implicit);
    return flags | coefficientSqrt(cx, ex);
}

@safe pure nothrow @nogc
ExceptionFlags coefficientExp(T)(ref T cx, ref int ex, ref bool sx)
{
    //e^x = 1 + x + x2/2! + x3/3! + x4/4! ...
    //to avoid overflow and underflow:
    //x^n/n! = (x^(n-1)/(n-1)! * x/n
    
    ExceptionFlags flags;

    //save x for repeated multiplication
    immutable Unqual!T cxx = cx;
    immutable exx = ex;
    immutable sxx = sx;

    //shadow value
    Unqual!T cy;
    int ey = 0;
    bool sy = false;

    Unqual!T cf = cx;
    int ef = ex;
    bool sf = sx;

    if (coefficientAdd(cx, ex, sx, T(1U), 0, false, RoundingMode.implicit) & ExceptionFlags.overflow)
        return ExceptionFlags.overflow;
    
    
    Unqual!T n = 1U;

    do
    {
        cy = cx;
        ey = ex;
        sy = sx;

        Unqual!T cp = cxx;
        int ep = exx;
        bool sp = sxx;

        coefficientDiv(cp, ep, sp, ++n, 0, false, RoundingMode.implicit);
        coefficientMul(cf, ef, sf, cp, ep, sp, RoundingMode.implicit);
        coefficientAdd(cx, ex, sx, cf, ef, sf, RoundingMode.implicit);

    } 
    while (!coefficientApproxEqu(cx, ex, sx, cy, ey, sy));

    return ExceptionFlags.inexact;
    
}

@safe pure nothrow @nogc
ExceptionFlags coefficientLog(T)(ref T cx, ref int ex, ref bool sx)
{
    
    assert(!sx); //only positive
    assert(cx);

    //ln(coefficient * 10^exponent) = ln(coefficient) + exponent * ln(10);

    static if (is(T:uint))
    {
        immutable uint ce = 2718281828U;
        immutable int ee = -9;
        immutable uint cl = 2302585093U;
        immutable int el = -9;

    }
    else static if (is(T:ulong))
    {
        immutable ulong ce = 2718281828459045235UL;
        immutable int ee = -18;
        immutable ulong cl = 2302585092994045684UL;
        immutable int el = -18;
    }
    else static if (is(T:uint128))
    {
        immutable uint128 ce = uint128("271828182845904523536028747135266249776");
        immutable int ee = -38;
        immutable uint128 cl = uint128("230258509299404568401799145468436420760");
        immutable int el = -38;
    }
    else
        static assert(0);

    //ln(x) = ln(n*e) = ln(n) + ln(e);
    //we divide x by e to find out how many times (n) we must add ln(e) = 1
    //ln(x + 1) taylor series works in the interval (-1 .. 1]
    //so our taylor series is valid for x in (0 .. 2]

    //save exponent for later
    int exponent = ex;
    ex = 0;
    
    enum one = T(1U);
    enum two = T(2U);

    Unqual!T n = 0U;
    bool ss = false;

    immutable aaa = cx;

    while (coefficientCmp(cx, ex, false, two, 0, false) >= 0)
    {
        coefficientDiv(cx, ex, sx, ce, ee, false, RoundingMode.implicit);
        ++n;
    }

    coefficientDiv(cx, ex, sx, ce, ee, false, RoundingMode.implicit);
    ++n;

    //ln(x) = (x - 1) - [(x - 1)^2]/2 + [(x - 1)^3]/3 - ....

    //initialize our result to x - 1;
    coefficientAdd(cx, ex, sx, one, 0, true, RoundingMode.implicit);
     
    //store cx in cxm1, this will be used for repeated multiplication
    //we negate the sign to alternate between +/-
    Unqual!T cxm1 = cx;
    int exm1 = ex;
    bool sxm1 = !sx;

    //shadow
    Unqual!T cy;
    int ey;
    bool sy;

    Unqual!T cd = cxm1;
    int ed = exm1;
    bool sd = !sxm1;

    Unqual!T i = 2U;

    do
    {
        cy = cx;
        ey = ex;
        sy = sx;

        coefficientMul(cd, ed, sd, cxm1, exm1, sxm1, RoundingMode.implicit);
        
        Unqual!T cf = cd;
        int ef = ed;
        bool sf = sd;

        coefficientDiv(cf, ef, sf, i++, 0, false, RoundingMode.implicit);
        coefficientAdd(cx, ex, sx, cf, ef, sf, RoundingMode.implicit);

        //writefln("%10d %10d %10d %10d %10d %10d", cx, ex, cy, ey, cx - cy, i);
    }
    while (!coefficientApproxEqu(cx, ex, sx, cy, ey, sy));
   


    coefficientAdd(cx, ex, sx, n, 0, false, RoundingMode.implicit);
    
    if (exponent != 0)
    {
        sy = exponent < 0;
        cy = sy ? cast(uint)(-exponent) : cast(uint)(exponent);
        ey = 0;
        coefficientMul(cy, ey, sy, cl, el, false, RoundingMode.implicit);
        coefficientAdd(cx, ex, sx, cy, ey, sy, RoundingMode.implicit);
    }

    //iterations 
    //decimal32 min:         15, max:         48 avg:      30.03
    //decimal64 min:         30, max:        234 avg:     149.25    


    return ExceptionFlags.inexact;
}

@safe pure nothrow @nogc
ExceptionFlags coefficientAtanh(T)(ref T cx, ref int ex, ref bool sx)
{
    //1/2*ln[(1 + x)/(1 - x)]

    assert (coefficientCmp(cx, ex, sx, T(1U), 0, true) > 0);
    assert (coefficientCmp(cx, ex, sx, T(1U), 0, false) < 0);

    //1/2*ln[(1 + x)/(1 - x)]

    Unqual!T cm1 = cx;
    int em1 = ex;
    bool sm1 = !sx;

    coefficientAdd(cm1, em1, sm1, T(1U), 0, false, RoundingMode.implicit);
    coefficientAdd(cx, ex, sx, T(1U), 0, false, RoundingMode.implicit);
    coefficientDiv(cx, ex, sx, cm1, em1, sm1, RoundingMode.implicit);
    coefficientLog(cx, ex, sx);
    coefficientMul(cx, ex, sx, T(5U), -1, false, RoundingMode.implicit);

    return ExceptionFlags.inexact;


}



enum
{
    s_e             = "2.7182818284590452353602874713526625",
    s_pi            = "3.1415926535897932384626433832795029",
    s_pi_2          = "1.5707963267948966192313216916397514",
    s_pi_4          = "0.7853981633974483096156608458198757",
    s_m_1_pi        = "0.3183098861837906715377675267450287",
    s_m_2_pi        = "0.6366197723675813430755350534900574",
    s_m_2_sqrtpi    = "1.1283791670955125738961589031215452",
    s_sqrt2         = "1.4142135623730950488016887242096981",
    s_sqrt1_2       = "0.7071067811865475244008443621048490",
    s_ln10          = "2.3025850929940456840179914546843642",
    s_log2t         = "3.3219280948873623478703194294893902",
    s_log2e         = "1.4426950408889634073599246810018921",
    s_log2          = "0.3010299956639811952137388947244930",
    s_log10e        = "0.4342944819032518276511289189166051",
    s_ln2           = "0.6931471805599453094172321214581766",

    s_sqrt3         = "1.7320508075688772935274463415058723",
    s_m_sqrt3       = "0.5773502691896257645091487805019574",
    s_pi_3          = "1.0471975511965977461542144610931676",
    s_pi_6          = "0.5235987755982988730771072305465838",

    s_sqrt2_2       = "0.7071067811865475244008443621048490",
    s_sqrt3_2       = "0.8660254037844386467637231707529361",
    s_5pi_6         = "2.6179938779914943653855361527329190",
    s_3pi_4         = "2.3561944901923449288469825374596271",
    s_2pi_3         = "2.0943951023931954923084289221863352",
    s_onethird      = "0.3333333333333333333333333333333333",
    s_twothirds     = "0.6666666666666666666666666666666667",
    s_5_6           = "0.8333333333333333333333333333333333",
    s_1_6           = "0.1666666666666666666666666666666667",
    s_m_1_2pi       = "0.1591549430918953357688837633725144",
    s_pi2           = "6.2831853071795864769252867665590058",


    s_f2            = "0.5000000_000000000_000000000000000000", // 1/2!
    s_f3            = "0.1666666_666666666_666666666666666667", // 1/3!
    s_f4            = "0.0416666_666666666_666666666666666667", // 1/4!
    s_f5            = "0.0083333_333333333_333333333333333333", // 1/5!
    s_f6            = "0.0013888_888888888_888888888888888889", // 1/6!
    s_f7            = "0.0001984_126984126_984126984126984127", // 1/7!
    s_f8            = "0.0000248_015873015_873015873015873016", // 1/8!
    s_f9            = "0.0000027_557319223_985890652557319223", // 1/9!
    s_f10           = "0.0000002_755731922_398589065255731922", // 1/10!
    s_f11           = "0.0000000_250521083_854417187750521084", // 1/11!
    s_f12           = "0.0000000_020876756_987868098979210090", // 1/12!
    s_f13           = "0.0000000_001605904_383682161459939238", // 1/13!
    s_f14           = "0.0000000_000114707_455977297247138517", // 1/14!
    s_f15           = "0.0000000_000007647_163731819816475901", // 1/15!
    s_f16           = "0.0000000_000000477_947733238738529744", // 1/16!
    s_f17           = "0.0000000_000000028_114572543455207632", // 1/17!
    s_f18           = "0.0000000_000000001_561920696858622646", // 1/18!
    s_f19           = "0.0000000_000000000_082206352466243297", // 1/19!
    s_f20           = "0.0000000_000000000_004110317623312165", // 1/20!
    s_f21           = "0.0000000_000000000_000195729410633913", // 1/21!
    s_f22           = "0.0000000_000000000_000008896791392451", // 1/22!
    s_f23           = "0.0000000_000000000_000000386817017063", // 1/23!
    s_f24           = "0.0000000_000000000_000000016117375711", // 1/24!
    s_f25           = "0.0000000_000000000_000000000644695028", // 1/25!
    s_f26           = "0.0000000_000000000_000000000024795963", // 1/26!
    s_f27           = "0.0000000_000000000_000000000000918369", // 1/27!
    s_f28           = "0.0000000_000000000_000000000000032799", // 1/28!
    s_f29           = "0.0000000_000000000_000000000000001131", // 1/29!
    s_f30           = "0.0000000_000000000_000000000000000038", // 1/30!
    s_f31           = "0.0000000_000000000_000000000000000001", // 1/31!

    s_m3            = "0.3333333_333333333_333333333333333333",
    s_m5            = "0.2000000_000000000_000000000000000000",
    s_m7            = "0.1428571_428571428_571428571428571429",
    s_m9            = "0.1111111_111111111_111111111111111111",
    s_m11           = "0.0909090_909090909_090909090909090909",
    s_m13           = "0.0769230_769230769_230769230769230769",
    s_m15           = "0.0666666_666666666_666666666666666667",
    s_m17           = "0.0588235_294117647_058823529411764706",
    s_m19           = "0.0526315_789473684_210526315789473684",
    s_m21           = "0.0476190_476190476_190476190476190476",
    s_m23           = "0.0434782_608695652_173913043478260869",
    s_m25           = "0.0400000_000000000_000000000000000000",
    s_m27           = "0.0370370_370370370_370370370370370371",
    s_m29           = "0.0344827_586206896_551724137931034483",
    s_m31           = "0.0322580_645161290_322580645161290326",
    s_m33           = "0.0303030_303030303_030303030303030303",
    s_m35           = "0.0285714_285714285_714285714285714285",
    s_m37           = "0.0270270_270270270_270270270270270270",
    s_m39           = "0.0256410_256410256_410256410256410256",
    s_m41           = "0.0243902_439024390_243902439024390244",
    s_m43           = "0.0232558_139534883_720930232558139535",
    s_m45           = "0.0222222_222222222_222222222222222222",
    s_m47           = "0.0212765_957446808_510638297872340426",
    s_m49           = "0.0204081_632653061_224489795918367347",
    s_m51           = "0.0196078_431372549_019607843137254902",
    s_m53           = "0.0188679_245283018_867924528301886792",
    s_m55           = "0.018181818181818181818181818181818182",
    s_m57           = "0.0175438_596491228_070175438596491228",
    s_m59           = "0.0169491_525423728_813559322033898305",
    s_m61           = "0.0163934_426229508_196721311475409836",
    s_m63           = "0.0158730_158730158_730158730158730159",
    s_m65           = "0.0153846_153846153_846153846153846154",
    s_m67           = "0.0149253_731343283_582089552238805970",
    s_m69           = "0.0144927_536231884_057971014492753623",
}

struct IEEECompliant
{
    string name;
    int page;
}

D parse(D, R)(ref R range)
if (isInputRange!R && isSomeChar!(ElementType!R) && isDecimal!D)
{
    Unqual!D result;
    auto flags = parse(range, result, D.realPrecision(DecimalControl.precision), DecimalControl.rounding);
    if (flags)
        DecimalControl.raiseFlags(flags);
}

//10 bit encoding
@safe pure nothrow @nogc
private uint packDPD(const uint d1, const uint d2, const uint d3)
{
    uint x = ((d1 & 8) >>> 1) | ((d2 & 8) >>> 2) | ((d3 & 8) >>> 3);

    switch(x)
    {
        case 0: 
            return (d1 << 7) | (d2 << 4) | d3;
        case 1:
            return (d1 << 7) | (d2 << 4) | (d3 & 1) | 8;
        case 2:
            return (d1 << 7) | ((d3 & 6) << 4) | ((d2 & 1) << 4) | (d3 & 1) | 10;
        case 3:
            return (d1 << 7) | ((d2 & 1) << 4) | (d3 & 1) | 78;
        case 4:
            return ((d3 & 6) << 7) | ((d1 & 1) << 7) | (d2 << 4) | (d3 & 1) | 12;
        case 5:
            return ((d2 & 6) << 7) | ((d1 & 1) << 7) | ((d2 & 1) << 4) | (d3 & 1) | 46;
        case 6:
            return ((d3 & 6) << 7) | ((d1 & 1) << 7) | ((d2 & 1) << 4) | (d3 & 1) | 14;
        case 7:
            return ((d1 & 1) << 7) | ((d2 & 1) << 4) | (d3 & 1) | 110;
        default:
            assert(0);
    }
}

//10 bit decoding
@safe pure nothrow @nogc
private void unpackDPD(const uint declet, out uint d1, out uint d2, out uint d3)
{
    uint x = declet & 14;
    uint decoded;
    switch (x)
    {
        case 0:
            decoded = ((declet & 896) << 1) | (declet & 119);
            break;
        case 1:
            decoded = ((declet & 128) << 1) | (declet & 113) | ((declet & 768) >> 7) | 2048;
            break;
        case 2: 
            decoded = ((declet & 896) << 1) | (declet & 17) | ((declet & 96) >> 4) | 128;
            break;
        case 3:
            decoded = ((declet & 896) << 1) | (declet & 113) | 8;
            break;
        case 4: 
            decoded = ((declet & 128) << 1) | (declet & 17) | ((declet & 768) >> 7) | 2176;
            break;
        case 5:
            decoded = ((declet & 128) << 1) | (declet & 17) | ((declet & 768) >> 3) | 2056;
            break;
        case 6:
            decoded = ((declet & 896) << 1) | (declet & 17) | 136;
            break;
        case 7: 
            decoded = ((declet & 128) << 1) | (declet & 17) | 2184;
            break;
        default:
            assert(0);
    }

    d1 = (decoded & 3840) >> 8;
    d2 = (decoded & 240) >> 4;
    d3 = (decoded & 15);
}