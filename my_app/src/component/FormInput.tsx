import React from 'react'

export const FormInput = ({errors, label, id, ...inputProps}: {errors: any, label: any, id: any}) => {
    return <>
        <label htmlFor={id}>{label}</label>
        <input
            id={id}
            {...inputProps}
        />
        {errors && <div>{errors.message}</div>}
    </>
}