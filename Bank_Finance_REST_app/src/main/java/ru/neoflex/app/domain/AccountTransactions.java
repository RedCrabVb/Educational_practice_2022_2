package ru.neoflex.app.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.Date;

@Entity
@Table(name = "t_account_transations")
@Getter
@Setter
@NoArgsConstructor
public class AccountTransactions {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long accountTransactionsId;
    @ManyToOne
    private TypeTransactions typeTransactions;
    private int amount;
    private String currency;
    @ManyToOne
    private User tUser;
    @Transient
    private String transferAccount;
    private Date date;
}
